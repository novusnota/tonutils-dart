import 'dart:math' show log;

import '../../cell/api.dart' show beginCell, Builder;
import 'api.dart' show findCommonPrefix;

//
// Tree Build
//

String _pad(String src, int size) {
  var padding = src.length < size ? '0' * (size - src.length) : '';
  return padding + src;
}

/// Either NodeFork or NodeLeaf
sealed class Node<T> {}

/// ({Edge<T> left, Edge<T> right})
class NodeFork<T> extends Node<T> {
  Edge<T> left;
  Edge<T> right;

  NodeFork({
    required this.left,
    required this.right,
  });
}

/// ({T value})
class NodeLeaf<T> extends Node<T> {
  T value;

  NodeLeaf({
    required this.value,
  });
}

/// ({String label, Node<T> node})
class Edge<T> {
  String label;
  Node<T> node;

  Edge({
    required this.label,
    required this.node,
  });
}

Map<String, T> _removePrefixMap<T>(Map<String, T> src, int length) {
  if (length == 0) {
    return src;
  }
  var res = <String, T>{};
  for (var k in src.keys) {
    // ignore: null_check_on_nullable_type_parameter
    res[k.substring(length)] = src[k]!;
  }
  return res;
}

/// Throws 'Internal inconsistency...' if the [src] is empty or either one of forks is empty
({
  Map<String, T> left,
  Map<String, T> right,
}) _forkMap<T>(Map<String, T> src) {
  if (src.isEmpty) {
    throw 'Internal inconsistency: passed map is empty';
  }

  var left = <String, T>{};
  var right = <String, T>{};

  for (var k in src.keys) {
    // ignore: null_check_on_nullable_type_parameter
    var d = src[k]!;
    if (k.startsWith('0')) {
      left[k.substring(1)] = d;
    } else {
      right[k.substring(1)] = d;
    }
  }

  if (left.isEmpty) {
    throw 'Internal inconsistency: left map is empty';
  }
  if (right.isEmpty) {
    throw 'Internal inconsistency: right map is empty';
  }

  return (left: left, right: right);
}

/// Throws 'Internal inconsistency...' if the [src] is empty
Edge<T> _buildEdge<T>(Map<String, T> src) {
  if (src.isEmpty) {
    throw 'Internal inconsistency: passed map is empty';
  }

  final label = findCommonPrefix(List.of(src.keys));

  return Edge<T>(
    label: label,
    node: _buildNode(_removePrefixMap(src, label.length)),
  );
}

/// Throws 'Internal inconsistency...' if the [src] is empty
Node<T> _buildNode<T>(Map<String, T> src) {
  if (src.isEmpty) {
    throw 'Internal inconsistency: passed map is empty';
  }
  if (src.length == 1) {
    return NodeLeaf<T>(value: List.of(src.values)[0]);
  }

  var (left: left, right: right) = _forkMap(src);

  return NodeFork<T>(
    left: _buildEdge<T>(left),
    right: _buildEdge<T>(right),
  );
}

Edge<T> buildTree<T>(Map<BigInt, T> src, int keyLength) {
  var converted = <String, T>{};
  var list = List.of(src.keys);

  for (var i = 0; i < list.length; i += 1) {
    final padded = _pad(list[i].toRadixString(2), keyLength);
    // ignore: null_check_on_nullable_type_parameter
    converted[padded] = src[list[i]]!;
  }

  // Calculate root label
  return _buildEdge(converted);
}

//
// Serialization
//

/// Returns a Builder, and writes a short label into it
Builder writeLabelShort(String src, Builder to) {
  // Header
  to.storeBit(0);

  // Unary length
  for (var i = 0; i < src.length; i += 1) {
    to.storeBit(1);
  }
  to.storeBit(0);

  // Value
  for (var i = 0; i < src.length; i += 1) {
    to.storeBit(src[i] == '1' ? 1 : 0);
  }
  return to;
}

int _labelShortLength(String src) {
  return 1 + src.length + 1 + src.length;
}

/// Returns a Builder, and writes a long label into it
Builder writeLabelLong(String src, int keyLength, Builder to) {
  // Header
  to.storeBit(1);
  to.storeBit(0);

  // Length
  var length = (log(keyLength + 1) / log(2)).ceil();
  to.storeUint(BigInt.from(src.length), length);

  // Value
  for (var i = 0; i < src.length; i += 1) {
    to.storeBit(src[i] == '1' ? 1 : 0);
  }

  return to;
}

int _labelLongLength(String src, int keyLength) {
  return 1 + 1 + (log(keyLength + 1) / log(2)).ceil() + src.length;
}

/// Returns nothing, writes the same label into the Builder [to]
writeLabelSame(int value, int length, int keyLength, Builder to) {
  // Header
  to.storeBit(1);
  to.storeBit(1);

  // Value
  to.storeBit(value);

  // Length
  var len = (log(keyLength + 1) / log(2)).ceil();
  to.storeUint(BigInt.from(length), len);
}

int _lableSameLength(int keyLength) {
  return 1 + 1 + 1 + (log(keyLength + 1) / log(2)).ceil();
}

bool _isSame(String src) {
  if (src.isEmpty || src.length == 1) {
    return true;
  }
  for (var i = 0; i < src.length; i += 1) {
    if (src[i] != src[0]) {
      return false;
    }
  }
  return true;
}

String detectLabelType(String src, int keyLength) {
  var kind = 'short';
  var kindLength = _labelShortLength(src);

  var longLength = _labelLongLength(src, keyLength);
  if (longLength < kindLength) {
    kindLength = longLength;
    kind = 'long';
  }

  if (_isSame(src)) {
    var sameLength = _lableSameLength(keyLength);
    if (sameLength < kindLength) {
      kindLength = sameLength;
      kind = 'same';
    }
  }

  return kind;
}

void _writeLabel(String src, int keyLength, Builder to) {
  var type = detectLabelType(src, keyLength);
  switch (type) {
    case 'short':
      writeLabelShort(src, to);
    case 'long':
      writeLabelLong(src, keyLength, to);
    case 'same':
      writeLabelSame(src[0] == '1' ? 1 : 0, src.length, keyLength, to);
    case _:
      throw 'Impossible';
  }
}

void _writeNode<T>(
  Node<T> src,
  int keyLength,
  void Function(T src, Builder cell) serializer,
  Builder to,
) {
  switch (src) {
    case NodeLeaf<T>():
      serializer(src.value, to);

    case NodeFork<T>():
      final leftCell = beginCell();
      final rightCell = beginCell();
      _writeEdge(src.left, keyLength - 1, serializer, leftCell);
      _writeEdge(src.right, keyLength - 1, serializer, rightCell);
      to.storeRef(leftCell);
      to.storeRef(rightCell);
  }
}

void _writeEdge<T>(
  Edge<T> src,
  int keyLength,
  void Function(T src, Builder cell) serializer,
  Builder to,
) {
  _writeLabel(src.label, keyLength, to);
  _writeNode<T>(src.node, keyLength - src.label.length, serializer, to);
}

void serializeDict<T>(
  Map<BigInt, T> src,
  int keyLength,
  void Function(T src, Builder cell) serializer,
  Builder to,
) {
  final tree = buildTree<T>(src, keyLength);
  _writeEdge(tree, keyLength, serializer, to);
}
