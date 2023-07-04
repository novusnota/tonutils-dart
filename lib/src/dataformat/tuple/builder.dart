import 'dart:typed_data';

import '../address/api.dart' show Address;
import '../cell/api.dart' show Cell, beginCell, Slice;
import 'api.dart'
    show TupleItem, TiTuple, TiBuilder, TiCell, TiSlice, TiInt, TiNull;

class TupleBuilder {
  final List<TupleItem> _tuple = <TupleItem>[];

  void writeInt([BigInt? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiInt(v));
  }

  void writeBool([bool? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiInt(v == true ? -BigInt.one : BigInt.zero));
  }

  void writeList([Uint8List? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiSlice(beginCell().storeList(v).endCell()));
  }

  void writeString([String? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiSlice(beginCell().storeStringTail(v).endCell()));
  }

  void writeCell([Cell? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiCell(v));
  }

  void writeCellAsSlice([Cell? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiSlice(v));
  }

  void writeSlice([Slice? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiSlice(v.asCell()));
  }

  void writeCellAsBuilder([Cell? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiBuilder(v));
  }

  void writeBuilder([Slice? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiBuilder(v.asCell()));
  }

  void writeTuple([List<TupleItem>? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiTuple(v));
  }

  void writeAddress([Address? v]) {
    if (v == null) {
      _tuple.add(TiNull());
      return;
    }
    _tuple.add(TiSlice(beginCell().storeAddress(v).endCell()));
  }

  List<TupleItem> build() {
    return List.of(_tuple);
  }
}
