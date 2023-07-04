import 'dart:typed_data';

import '../../bitstring/api.dart' show BitString;
import '../../cell/cell.dart' show Cell, CellType;

/// Returns int references descriptor
int getRefsDescriptor(List<Cell> refs, int level, CellType type) {
  return refs.length + (type != CellType.ordinary ? 1 : 0) * 8 + level * 32;
}

/// Returns int bits descriptor
int getBitsDescriptor(BitString bits) {
  var len = bits.length / 8;
  return len.ceil() + len.floor();
}

/// Returns Uint8List of representation
Uint8List getRepr(
  BitString originalBits,
  BitString bits,
  List<Cell> refs,
  int level,
  CellType type,
) {
  final bitsLen = (bits.length / 8).ceil();
  final repr = Uint8List(2 + bitsLen + (2 + 32) * refs.length);

  var reprCursor = 0;
  repr[reprCursor] = getRefsDescriptor(refs, level, type);
  reprCursor += 1;
  repr[reprCursor] = getBitsDescriptor(originalBits);
  reprCursor += 1;

  var padded = bits.toPaddedList();
  List.writeIterable(repr, reprCursor, padded);
  reprCursor += bitsLen;

  for (var i = 0; i < refs.length; i += 1) {
    int childDepth;
    switch (type) {
      case CellType.merkleProof:
      case CellType.merkleUpdate:
        childDepth = refs[i].depth(level + 1);

      case _:
        childDepth = refs[i].depth(level);
    }
    repr[reprCursor] = (childDepth / 256).floor();
    reprCursor += 1;
    repr[reprCursor] = childDepth % 256;
    reprCursor += 1;
  }

  for (var i = 0; i < refs.length; i += 1) {
    Uint8List childHash;
    switch (type) {
      case CellType.merkleProof:
      case CellType.merkleUpdate:
        childHash = refs[i].hash(level + 1);
      case _:
        childHash = refs[i].hash(level);
    }
    List.writeIterable(repr, reprCursor, childHash);
    reprCursor += 32;
  }

  return repr;
}
