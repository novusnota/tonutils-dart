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
    return fromString(src.toStringAsPrecision(21));
  }

  /// Returns BigInt nano value from double
  static BigInt fromDouble(double src) {
    return fromString(src.toStringAsPrecision(21));
  }

  /// Returns BigInt nano value from BigInt
  static BigInt fromBigInt(BigInt src) {
    return src * multiplier;
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
      throw 'Invalid number, "$str"';
    }
    var parts = str.split('.');
    if (parts.length > 2) {
      throw 'Invalid number, too many dots: "$str"';
    }

    var whole = parts[0];
    var frac = parts.length == 2 ? parts[1] : '0';

    if (whole.isEmpty) {
      whole = '0';
    }
    if (frac.isEmpty) {
      frac = '0';
    }
    if (frac.length > 9) {
      frac = frac.substring(0, 9);
    } else if (frac.length < 9) {
      frac += '0' * (9 - frac.length);
    }

    var r = BigInt.parse(whole, radix: 10) * multiplier +
        BigInt.parse(frac, radix: 10);

    return neg ? -r : r;
  }

  /// Returns int from nano value
  static int toInt(BigInt src) {
    return int.parse(asString(src), radix: 10);
  }

  /// Returns BigInt from nano value
  static BigInt toBigInt(BigInt src) {
    return BigInt.parse(asString(src), radix: 10);
  }

  // TODO: toNum or toDouble -- no, as nano would always be int!

  /// Returns a String from either BigInt, int, num or String
  static String asString(dynamic src) {
    BigInt v;

    switch (src.runtimeType) {
      case String:
        v = BigInt.parse((src as String).split('.')[0], radix: 10);
      case BigInt:
        v = src as BigInt;
      case int:
        v = BigInt.from(src as int);
      case double:
        v = BigInt.from(src as double);
      case _:
        throw 'Expected BigInt, int, double, or String, but got: $src';
    }

    var neg = false;
    if (v.isNegative) {
      neg = true;
      v = -v;
    }

    var frac = v % multiplier;
    var fracStr = frac.toString();

    if (fracStr.length < 9) {
      fracStr = '0' * (9 - fracStr.length) + fracStr;
    }

    // fracStr = RegExp(r'^([0-9]*[1-9]|0)(0*)')
    //     .allMatches(fracStr)
    //     .elementAt(1)
    //     .toString();
    fracStr =
        RegExp(r'^([0-9]*[1-9]|0)(0*)').firstMatch(fracStr)?.group(1) ?? '';

    var whole = (v / multiplier).truncate();
    var value = '$whole${fracStr == '0' ? '' : '.$fracStr'}';

    return neg ? '-$value' : value;
  }
}
