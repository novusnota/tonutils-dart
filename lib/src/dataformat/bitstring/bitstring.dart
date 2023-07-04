import 'dart:typed_data';

import 'package:convert/convert.dart';

import 'bitbuilder.dart' show BitBuilder;

/// BitString in Uint8List with an offset and a length
class BitString {
  static final empty = BitString(Uint8List(0), 0, 0);

  final int _length;
  final int _offset;
  final Uint8List _data;

  BitString(this._data, this._offset, this._length) {
    if (_length < 0) {
      throw 'Length $_length is out of bounds';
    }

    assert(_length >= 0);
  }

  int get length {
    return _length;
  }

  /// Returns the bit at the specified index: 1 if the bit is set, 0 otherwise
  int at(int index) {
    if (index >= _length || index < 0) {
      throw 'Index $index is out of bounds of $_length';
    }

    var byteIndex = (_offset + index) >> 3;
    var bitIndex = 7 - ((_offset + index) % 8); // NOTE: works on big-endian.

    return (_data[byteIndex] & (1 << bitIndex)) != 0 ? 1 : 0;
  }

  /// Returns a substring of the BitString as a new BitString
  BitString substring(int offset, int length) {
    if (offset >= _length || offset < 0) {
      throw 'Offset $offset is out of bounds of $_length';
    }

    if (length == 0) {
      return empty;
    }

    if (offset + length > _length) {
      throw 'Offset $offset + Length $length is out of bounds of $_length';
    }

    return BitString(_data, _offset + offset, length);
  }

  /// Returns Uint8List if the BitString is aligned to bytes, null otherwise
  Uint8List? sublist(int offset, int length) {
    if (offset >= _length || offset < 0) {
      throw 'Offset $offset is out of bounds of $_length';
    }

    if (offset + length > _length) {
      throw 'Offset $offset + Length $length is out of bounds of $_length';
    }

    if (length % 8 != 0) {
      return null;
    }

    if ((_offset + offset) % 8 != 0) {
      return null;
    }

    var start = ((_offset + offset) >> 3);
    var end = start + (length >> 3);

    return _data.sublist(start, end);
  }

  /// Returns true if the BitStrings are equal, false otherwise
  bool equals(BitString b) {
    if (_length != b.length) {
      return false;
    }
    for (var i = 0; i < _length; i += 1) {
      if (at(i) != b.at(i)) {
        return false;
      }
    }
    return true;
  }

  /// Returns a padded Uint8List
  Uint8List toPaddedList() {
    var unalignedLength = (length / 8).ceil() * 8;
    var builder = BitBuilder(unalignedLength);
    builder.writeBits(this);

    var padding = unalignedLength - length;
    for (var i = 0; i < padding; i += 1) {
      if (i == 0) {
        builder.writeBit(1);
        continue;
      }

      builder.writeBit(0);
    }

    return builder.list();
  }

  /// Returns string of formatted bits
  @override
  String toString() {
    final padded = toPaddedList();
    String toHexUpper(Uint8List list) => hex.encode(list).toUpperCase();

    if (_length % 4 == 0) {
      final s = toHexUpper(padded.sublist(0, (_length / 8).ceil()));

      if (_length % 8 == 0) {
        return s;
      }

      return s.substring(0, s.length - 1);
    }

    final hexStr = toHexUpper(padded);

    if (_length % 8 <= 4) {
      return '${hexStr.substring(0, hexStr.length - 1)}_';
    }

    return '${hexStr}_';
  }
}
