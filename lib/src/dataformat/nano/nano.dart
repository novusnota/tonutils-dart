import 'dart:convert';

/// For converting to and from nano values
sealed class Nano {
  static final BigInt multiplier = BigInt.from(1e9);

  /// Returns BigInt nano value from int
  static BigInt fromInt(int src) {
    return BigInt.from(src) * multiplier;
  }

  /// Returns BigInt nano value from num
  static BigInt fromNum(num src) {
    return BigInt.from(src) * multiplier;
  }

  /// Returns int from nano value
  static int toInt(BigInt src) {
    return int.parse(asString(src));
  }

  /// Returns BigInt nano value from BigInt
  static BigInt fromBigInt(BigInt src) {
    return src * multiplier;
  }

  /// Returns BigInt from nano value
  static BigInt toBigInt(BigInt src) {
    return BigInt.parse(asString(src));
  }

  /// Returns BigInt nano value from String
  static BigInt fromString(String src) {
    var str = String.fromCharCodes(utf8.encode(src));

    var neg = false;
    while (str.startsWith('-')) {
      neg = !neg;
      str = str.substring(1);
    }

    if (str == '.') {
      throw 'Invalid number';
    }
    var parts = str.split('.');
    if (parts.length > 2) {
      throw 'Invalid number';
    }

    var whole = parts[0];
    var frac = parts[1];

    if (whole.isEmpty) {
      whole = '0';
    }
    if (frac.isEmpty) {
      frac = '0';
    }
    if (frac.length > 9) {
      throw 'Invalid number';
    }
    while (frac.length < 9) {
      frac += '0';
    }

    var r = BigInt.parse(whole) * BigInt.from(1e9) + BigInt.parse(frac);
    if (neg) {
      r = -r;
    }

    return r;
  }

  /// Returns a String from either BigInt, int, num or String
  static String asString(dynamic src) {
    BigInt v;

    switch (src) {
      case String:
        v = BigInt.parse(src as String);
      case BigInt:
        v = src as BigInt;
      case int:
        v = BigInt.from(src as int);
      case num:
        v = BigInt.from(src as num);
      case _:
        throw 'Expected BigInt, int, num or String, but got: $src';
    }

    var neg = false;
    if (v.isNegative) {
      neg = true;
      v = -v;
    }

    var frac = v.modPow(BigInt.one, BigInt.from(1e9));
    var fracStr = frac.toString();

    while (fracStr.length < 9) {
      fracStr = '0$fracStr';
    }
    // fracStr = RegExp(r'^([0-9]*[1-9]|0)(0*)')
    //     .allMatches(fracStr)
    //     .elementAt(1)
    //     .toString();
    fracStr =
        RegExp(r'^([0-9]*[1-9]|0)(0*)').firstMatch(fracStr)?.group(1) ?? '';

    var whole = (v / BigInt.from(1e9)).truncate();
    var wholeStr = whole.toString();

    var value = '$wholeStr${fracStr == '0' ? '' : '.$fracStr'}';
    if (neg) {
      value = '-$value';
    }

    return value;
  }
}
