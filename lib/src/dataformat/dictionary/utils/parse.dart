import 'dart:math' show log;

import '../../cell/api.dart' show Slice;

int _readUnaryLength(Slice slice) {
  var res = 0;
  while (slice.loadBit() != 0) {
    res += 1;
  }
  return res;
}

void _doParse<V>(
  String prefix,
  Slice slice,
  int n,
  Map<BigInt, V> res,
  V Function(Slice src) extractor,
) {
  var lb0 = slice.loadBit();
  var prefixLength = 0;
  var pp = StringBuffer(prefix);

  if (lb0 == 0) {
    // short label

    prefixLength = _readUnaryLength(slice);

    for (var i = 0; i < prefixLength; i += 1) {
      pp.write(slice.loadBit().toString());
    }
  } else {
    var lb1 = slice.loadBit();
    if (lb1 == 0) {
      // long label

      prefixLength = slice.loadUint((log(n + 1) / log(2)).ceil());

      for (var i = 0; i < prefixLength; i += 1) {
        pp.write(slice.loadBit().toString());
      }
    } else {
      // same label

      var bit = slice.loadBit().toString();
      prefixLength = slice.loadUint((log(n + 1) / log(2)).ceil());

      for (var i = 0; i < prefixLength; i += 1) {
        pp.write(bit);
      }
    }
  }

  if (n - prefixLength == 0) {
    res[BigInt.parse(pp.toString(), radix: 2)] = extractor(slice);
  } else {
    // NOTE: left and right branches are implicitly containing 0 and 1 as prefixes
    var left = slice.loadRef();
    var right = slice.loadRef();

    if (left.isExotic == false) {
      _doParse(
        '${pp}0',
        left.beginParse(),
        n - prefixLength - 1,
        res,
        extractor,
      );
    }
    if (right.isExotic == false) {
      _doParse(
        '${pp}1',
        right.beginParse(),
        n - prefixLength - 1,
        res,
        extractor,
      );
    }
  }
}

Map<BigInt, V> parseDict<V>(
  Slice? sc,
  int keySize,
  V Function(Slice src) extractor,
) {
  var res = <BigInt, V>{};
  if (sc != null) {
    _doParse('', sc, keySize, res, extractor);
  }
  return res;
}
