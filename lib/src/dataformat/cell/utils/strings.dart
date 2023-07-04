import 'dart:convert';
import 'dart:typed_data';
import '../api.dart' show beginCell, Builder, Cell, Slice;

Uint8List _readList(Slice slice) {
  if (slice.remainingBits % 8 != 0) {
    throw 'Invalid string length: ${slice.remainingBits}';
  }
  if (slice.remainingRefs != 0 && slice.remainingRefs != 1) {
    throw 'Invalid number of references: ${slice.remainingRefs}';
  }
  if (slice.remainingRefs == 1 && (1023 - slice.remainingBits) > 7) {
    throw 'Invalid string length: ${slice.remainingBits / 8}';
  }

  Uint8List res;
  if (slice.remainingBits == 0) {
    res = Uint8List(0);
  } else {
    res = slice.loadList(slice.remainingBits ~/ 8);
  }

  if (slice.remainingRefs == 1) {
    var bb = BytesBuilder();
    bb.add(res);
    bb.add(_readList(slice.loadRef().beginParse()));

    res = bb.takeBytes();
  }

  return res;
}

void _writeList(Uint8List src, Builder builder) {
  if (src.isEmpty) {
    return;
  }
  assert(src.isNotEmpty);

  var nbytes = (builder.availableBits / 8).floor();
  if (src.length > nbytes) {
    var a = src.sublist(0, nbytes);
    var t = src.sublist(nbytes);
    builder = builder.storeList(a);
    var bb = beginCell();
    _writeList(t, bb);
    builder = builder.storeRef(bb.endCell());
  } else {
    builder = builder.storeList(src);
  }
}

/// Returns a String from a Slice
String readString(Slice slice) {
  return _readList(slice).toString();
}

/// Returns nothing, writes a String into a Builder
void writeString(String src, Builder builder) {
  _writeList(Uint8List.fromList(utf8.encode(src)), builder);
}

/// Returns a Cell from a String
Cell stringToCell(String src) {
  var builder = beginCell();
  _writeList(Uint8List.fromList(utf8.encode(src)), builder);

  return builder.endCell();
}
