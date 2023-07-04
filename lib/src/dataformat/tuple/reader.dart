import 'dart:typed_data';

import '../cell/api.dart' show Cell;
import '../address/api.dart' show InternalAddress;
import 'api.dart'
    show TiInt, TupleItem, TiTuple, TiBuilder, TiCell, TiNull, TiSlice;

class TupleReader {
  final List<TupleItem> _items;

  TupleReader(List<TupleItem> items) : _items = List.of(items);

  /// Returns number of remaining items as a int
  int get remaining => _items.length;

  /// Returns remaining items as a List<TupleItem>
  List<TupleItem> get items => _items;

  /// Returns a first item in the internal list
  ///
  /// Throws an 'EOF' if [_items] is empty
  TupleItem peek() {
    if (_items.isEmpty) {
      throw 'EOF';
    }
    return _items[0];
  }

  /// Returns a first item in the internal list and removes it from that list
  ///
  /// Throws an 'EOF' if [_items] is empty
  TupleItem pop() {
    if (_items.isEmpty) {
      throw 'EOF';
    }
    return _items.removeAt(0);
  }

  /// Returns the updated TupleReader after removing [n] entries from internal list
  ///
  /// Throws an 'EOF' if [n] is greater than [_items.length]
  TupleReader skip([int n = 1]) {
    if (n > _items.length) {
      throw 'EOF';
    }
    for (var i = 0; i < n; i += 1) {
      pop();
    }
    return this;
  }

  /// Returns a BigInt of popped first item of the internal list
  ///
  /// Throws a 'Not a number' if TupleItem type is not TiInt
  BigInt readBigInt() {
    var popped = pop();
    if (popped is! TiInt) {
      throw 'Not a number';
    }
    return popped.value;
  }

  // NOTE consider adding other code doc comments later

  BigInt? readBigIntOrNull() {
    var popped = pop();
    if (popped is TiNull) {
      return null;
    }
    if (popped is! TiInt) {
      throw 'Not a number';
    }
    return popped.value;
  }

  int readInt() {
    return readBigInt().toInt();
  }

  int? readIntOrNull() {
    var r = readBigIntOrNull();
    if (r == null) {
      return null;
    }
    return r.toInt();
  }

  bool readBool() {
    var r = readInt();
    return r == 0 ? false : true;
  }

  bool? readBoolOrNull() {
    var r = readIntOrNull();
    if (r == null) {
      return null;
    }
    return r == 0 ? false : true;
  }

  /// Throws 'Not a cell' if the type of the popped item is neither TiCell, TiSlice nor TiBuilder
  Cell readCell() {
    var popped = pop();
    switch (popped) {
      case TiCell():
        return popped.cell;
      case TiSlice():
        return popped.cell;
      case TiBuilder():
        return popped.cell;
      case _:
        throw 'Not a cell: $popped';
    }
  }

  /// Throws 'Not a cell' if the type of the popped item is neither TiNull, TiCell, TiSlice nor TiBuilder
  Cell? readCellOrNull() {
    var popped = pop();
    switch (popped) {
      case TiNull():
        return null;
      case TiCell():
        return popped.cell;
      case TiSlice():
        return popped.cell;
      case TiBuilder():
        return popped.cell;
      case _:
        throw 'Not a cell: $popped';
    }
  }

  /// Throws 'Not a cell' if the type of the popped item is neither TiCell, TiSlice nor TiBuilder
  InternalAddress readAddress() {
    return readCell().beginParse().loadInternalAddress();
  }

  /// Throws 'Not a cell' if the type of the popped item is neither TiNull, TiCell, TiSlice nor TiBuilder
  InternalAddress? readAddressOrNull() {
    var r = readCellOrNull();
    if (r == null) {
      return null;
    }
    return r.beginParse().loadInternalAddressOrNull();
  }

  /// Throws 'Not a tuple' if the type of the popped item is not TiTuple
  TupleReader readTuple() {
    var popped = pop();
    if (popped is! TiTuple) {
      throw 'Not a tuple';
    }
    return TupleReader(popped.items);
  }

  /// Throws 'Not a tuple' if the type of the popped item is neither TiNull nor TiTuple
  TupleReader? readTupleOrNull() {
    var popped = pop();
    if (popped is TiNull) {
      return null;
    }
    if (popped is! TiTuple) {
      throw 'Not a tuple';
    }
    return TupleReader(popped.items);
  }

  /// Throws 'Not a Uint8List' if either remainingRefs != 0 or remainingBits % 8 != 0 for the read Cell as a Slice
  Uint8List readList() {
    var s = readCell().beginParse();
    if (s.remainingRefs != 0) {
      throw 'Not a Uint8List';
    }
    if (s.remainingBits % 8 != 0) {
      throw 'Not a Uint8List';
    }
    return s.loadList(s.remainingBits ~/ 8);
  }

  /// Throws 'Not a Uint8List' if either remainingRefs != 0 or remainingBits % 8 != 0 for the read Cell as a Slice
  Uint8List? readListOrNull() {
    var first = peek();
    if (first is TiNull) {
      return null;
    }
    return readList();
  }

  readString() {
    var s = readCell().beginParse();
    return s.loadStringTail();
  }

  readStringOrNull() {
    var first = peek();
    if (first is TiNull) {
      return null;
    }
    var s = readCell().beginParse();
    return s.loadStringTail();
  }
}
