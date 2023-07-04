import 'package:collection/collection.dart';

import '../cell/api.dart' show beginCell, Builder, Cell, Slice;

final _int64max = BigInt.parse('9223372036854775807');
final _int64min = BigInt.parse('-9223372036854775808');

/// Base class for all tuple items (Ti's)
sealed class TupleItem {}

/// TupleItemTuple with List<TupleItem> items field
class TiTuple extends TupleItem {
  final List<TupleItem> items;

  TiTuple(this.items);
}

/// TupleItemBuilder with Cell cell field
class TiBuilder extends TupleItem {
  final Cell cell;

  TiBuilder(this.cell);
}

/// TupleItemCell with Cell cell field
class TiCell extends TupleItem {
  final Cell cell;

  TiCell(this.cell);
}

/// TupleItemTuple with Cell [cell] field
class TiSlice extends TupleItem {
  final Cell cell;

  TiSlice(this.cell);
}

/// TupleItemInt with BigInt value field
class TiInt extends TupleItem {
  final BigInt value;

  TiInt(this.value);
}

/// TupleItemNan
class TiNan extends TupleItem {}

/// TupleItemNull
class TiNull extends TupleItem {}

// vm_stk_null#00 = VmStackValue;
// vm_stk_tinyint#01 value:int64 = VmStackValue;
// vm_stk_int#0201_ value:int257 = VmStackValue;
// vm_stk_nan#02ff = VmStackValue;
// vm_stk_cell#03 cell:^Cell = VmStackValue;

// _ cell:^Cell st_bits:(## 10) end_bits:(## 10) { st_bits <= end_bits }
//   st_ref:(#<= 4) end_ref:(#<= 4) { st_ref <= end_ref } = VmCellSlice;
// vm_stk_slice#04 _:VmCellSlice = VmStackValue;
// vm_stk_builder#05 cell:^Cell = VmStackValue;
// vm_stk_cont#06 cont:VmCont = VmStackValue;

// vm_tupref_nil$_ = VmTupleRef 0;
// vm_tupref_single$_ entry:^VmStackValue = VmTupleRef 1;
// vm_tupref_any$_ {n:#} ref:^(VmTuple (n + 2)) = VmTupleRef (n + 2);
// vm_tuple_nil$_ = VmTuple 0;
// vm_tuple_tcons$_ {n:#} head:(VmTupleRef n) tail:^VmStackValue = VmTuple (n + 1);
// vm_stk_tuple#07 len:(## 16) data:(VmTuple len) = VmStackValue;

void _serializeTupleItem(TupleItem src, Builder builder) {
  switch (src) {
    case TiNull():
      builder.storeUint(BigInt.from(0x00), 8);

    case TiInt():
      if (_int64min <= src.value && src.value <= _int64max) {
        builder.storeUint(BigInt.from(0x01), 8);
        builder.storeInt(src.value, 64);
      } else {
        builder.storeUint(BigInt.from(0x0100), 15);
        builder.storeInt(src.value, 257);
      }

    case TiNan():
      builder.storeInt(BigInt.from(0x02ff), 16);

    case TiCell():
      builder.storeUint(BigInt.from(0x03), 8);
      builder.storeRef(src.cell);

    case TiSlice():
      builder.storeUint(BigInt.from(0x04), 8);
      builder.storeUint(BigInt.zero, 10);
      builder.storeUint(BigInt.from(src.cell.bits.length), 10);
      builder.storeUint(BigInt.zero, 3);
      builder.storeUint(BigInt.from(src.cell.refs.length), 3);
      builder.storeRef(src.cell);

    case TiBuilder():
      builder.storeUint(BigInt.from(0x05), 8);
      builder.storeRef(src.cell);

    case TiTuple():
      Cell? head;
      Cell? tail;

      for (var i = 0; i < src.items.length; i += 1) {
        var s = head;
        head = tail;
        tail = s;

        if (i > 1) {
          head = beginCell().storeRef(tail!).storeRef(head!).endCell();
        }

        var bc = beginCell();
        _serializeTupleItem(src.items[i], bc);
        tail = bc.endCell();
      }

      builder.storeUint(BigInt.from(0x07), 8);
      builder.storeUint(BigInt.from(src.items.length), 16);

      if (head != null) {
        builder.storeRef(head);
      }
      if (tail != null) {
        builder.storeRef(tail);
      }
  }
}

TupleItem _parseStackItem(Slice src) {
  var kind = src.loadUint(8);

  switch (kind) {
    case 0:
      return TiNull();

    case 1:
      return TiInt(src.loadIntBig(64));

    case 2:
      if (src.loadUint(7) == 0) {
        return TiInt(src.loadIntBig(257));
      } else {
        src.loadBit(); // should be 1
        return TiNan();
      }

    case 3:
      return TiCell(src.loadRef());

    case 4:
      var startBits = src.loadUint(10);
      var endBits = src.loadUint(10);
      var startRefs = src.loadUint(3);
      var endRefs = src.loadUint(3);

      var rs = src.loadRef().beginParse();
      rs.skip(startBits);
      var dt = rs.loadBits(endBits - startBits);

      var builder = beginCell().storeBits(dt);

      if (startRefs < endRefs) {
        for (var i = 0; i < startRefs; i += 1) {
          rs.loadRef();
        }
        for (var i = 0; i < endRefs - startRefs; i += 1) {
          builder.storeRef(rs.loadRef());
        }
      }
      return TiSlice(builder.endCell());

    case 5:
      return TiBuilder(src.loadRef());

    case 7:
      var length = src.loadUint(16);
      var items = <TupleItem>[];

      if (length > 1) {
        var head = src.loadRef().beginParse();
        var tail = src.loadRef().beginParse();
        items.insert(0, _parseStackItem(tail));

        for (var i = 0; i < length - 2; i += 1) {
          var origHead = head.clone(); // NOTE consider removing .clone() here
          head = origHead.loadRef().beginParse();
          tail = origHead.loadRef().beginParse();
          items.insert(0, _parseStackItem(tail));
        }

        items.insert(0, _parseStackItem(head));
      } else if (length == 1) {
        items.add(_parseStackItem(src.loadRef().beginParse()));
      }

      return TiTuple(items);

    case _:
      throw 'Unsupported stack item $kind';
  }
}

// Stack parsing
// Source: https://github.com/ton-foundation/ton/blob/ae5c0720143e231c32c3d2034cfe4e533a16d969/crypto/block/block.tlb#L783
//
// vm_stack#_ depth:(## 24) stack:(VmStackList depth) = VmStack;
// vm_stk_cons#_ {n:#} rest:^(VmStackList n) tos:VmStackValue = VmStackList (n + 1);
// vm_stk_nil#_ = VmStackList 0;

void _serializeTupleTail(List<TupleItem> src, Builder builder) {
  if (src.isEmpty) {
    return;
  }

  // rest:^(VmStackList n)
  var tail = beginCell();
  _serializeTupleTail(src.slice(0, src.length - 1), tail);
  builder.storeRef(tail.endCell());

  // tos
  _serializeTupleItem(src[src.length - 1], builder);
}

/// Returns a Cell out of the List<TupleItem>
Cell serializeTuple(List<TupleItem> src) {
  var builder = beginCell();
  builder.storeUint(BigInt.from(src.length), 24);
  var r = List.of(src);
  _serializeTupleTail(r, builder);

  return builder.endCell();
}

/// Returns a List<TupleItem> out of the Cell
List<TupleItem> parseTuple(Cell src) {
  var res = <TupleItem>[];
  var cs = src.beginParse();
  var size = cs.loadUint(24);

  for (var i = 0; i < size; i += 1) {
    var next = cs.loadRef();
    res.insert(0, _parseStackItem(cs));
    cs = next.beginParse();
  }

  return res;
}
