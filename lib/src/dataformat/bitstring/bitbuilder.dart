import 'dart:typed_data';

import '../address/api.dart' show Address, InternalAddress, ExternalAddress;
import 'bitstring.dart' show BitString;

/// Uses Uint8List for working with BitStrings
class BitBuilder {
  late Uint8List _list;
  late int _length;

  BitBuilder([int size = 1023]) {
    _list = Uint8List((size / 8).ceil());
    _length = 0;
  }

  /// Returns current number of bits written
  int get length {
    return _length;
  }

  /// Returns nothing, writes a bool as a single bit
  void writeBool(bool boolean) {
    writeBit(boolean ? 1 : 0);
  }

  /// Returns nothing, writes a single bit
  void writeBit(int bit) {
    if (_length > _list.length * 8) {
      throw 'BitBuilder overflow';
    }

    var vBit = true;
    if (bit <= 0) {
      vBit = false;
    }

    if (vBit) {
      _list[(_length ~/ 8) | 0] |= 1 << (7 - (_length % 8));
    }

    _length += 1;
  }

  /// Returns nothing, copies bits from BitString
  void writeBits(BitString src) {
    for (var i = 0; i < src.length; i += 1) {
      writeBit(src.at(i));
    }
  }

  /// Returns nothing, copies bits from Uint8List
  ///
  /// Throws 'BitBuilder overflow'
  void writeList(Uint8List src) {
    if (_length % 8 == 0) {
      if (_length + src.length * 8 > _list.length * 8) {
        throw 'BitBuilder overflow';
      }

      List.writeIterable(_list, _length ~/ 8, src);
      _length += src.length * 8;

      return;
    }

    for (var i = 0; i < src.length; i += 1) {
      writeUint(BigInt.from(src[i]), 8);
    }
  }

  /// Returns nothing, writes uint value from a BigInt
  void writeUint(BigInt value, int bits) {
    if (bits == 8 && _length % 8 == 0) {
      var v = value.toInt();
      if (v < 0 || v > 255) {
        throw 'Value $value is out range of $bits';
      }
      _list[_length ~/ 8] = v;
      _length += 8;
      return;
    }

    if (bits == 16 && _length % 16 == 0) {
      var v = value.toInt();
      if (v < 0 || v > 65536) {
        throw 'Value $value is out range of $bits';
      }
      _list[_length ~/ 8] = v >> 8;
      _list[_length ~/ 8 + 1] = v & 0xff;
      _length += 16;
      return;
    }

    if (bits < 0) {
      throw 'Invalid bit length $bits';
    }

    if (bits == 0) {
      if (value != BigInt.zero) {
        throw 'Bit length is $bits, but value is $value and not zero';
      }
      return;
    }

    var vBits = BigInt.one << bits;
    if (value < BigInt.zero || value >= vBits) {
      throw 'Bit length is $bits, but value is $value and it cannot fit in the given bit length';
    }

    var b = <int>[];
    while (value > BigInt.zero) {
      b.add((value % BigInt.two).toInt());
      value ~/= BigInt.two;
    }

    for (var i = 0; i < bits; i += 1) {
      var offset = bits - i - 1;
      if (offset < b.length) {
        writeBit(b[offset]);
      } else {
        writeBit(0);
      }
    }
  }

  /// Returns nothing, writes int value recursively
  void writeInt(BigInt value, int bits) {
    if (bits < 0) {
      throw 'Invalid bit length $bits';
    }

    if (bits == 0) {
      if (value != BigInt.zero) {
        throw 'Value $value is not zero for bits $bits';
      }
      return;
    }

    if (bits == 1) {
      if (value != BigInt.zero && value != -BigInt.one) {
        throw 'Value $value is not zero or -1 for bits $bits';
      }
      writeBit(value == -BigInt.one ? 1 : 0);
      return;
    }

    var vBits = BigInt.one << (bits - 1);
    if (value < -vBits || value >= vBits) {
      throw 'Value $value is out of range for $bits bits';
    }

    if (value < BigInt.zero) {
      writeBit(1);
      value += vBits;
    } else {
      writeBit(0);
    }

    writeUint(value, bits - 1);
  }

  /// Returns nothing, writes var uint value. Used for serializing coins.
  void writeVarUint(BigInt value, int bits) {
    if (bits < 0) {
      throw 'Invalid bit length $bits, expected 0 or bigger';
    }
    if (value < BigInt.zero) {
      throw 'Negative value $value, but expected non-negative';
    }
    if (value == BigInt.zero) {
      writeUint(BigInt.zero, bits);
      return;
    }

    // .bitLength?
    final sizeBytes = (value.toRadixString(2).length / 8).ceil();
    final sizeBits = sizeBytes * 8;

    writeUint(BigInt.from(sizeBytes), bits);
    writeUint(value, sizeBits);
  }

  /// Returns nothing, writes var int value. Used for serializing coins.
  void writeVarInt(BigInt value, int bits) {
    if (bits < 0) {
      throw 'Invalid bit length $bits';
    }

    if (value == BigInt.zero) {
      writeUint(BigInt.zero, bits);
      return;
    }

    var value2 = value > BigInt.zero ? value : -value;
    // .bitLength?
    final sizeBytes = 1 + (value2.toRadixString(2).length / 8).ceil();
    final sizeBits = sizeBytes * 8;

    writeUint(BigInt.from(sizeBytes), bits);
    writeInt(value, sizeBits);
  }

  /// Returns nothing, writes coins in var uint format
  void writeCoins(BigInt amount) {
    writeVarUint(amount, 4);
  }

  /// Returns nothing, writes an address
  void writeAddress(Address? address) {
    switch (address) {
      case null:
        writeUint(BigInt.zero, 2); // Empty

      case InternalAddress():
        writeUint(BigInt.two, 2); // Internal
        writeUint(BigInt.zero, 1);
        writeInt(address.workChain, 8);
        writeList(address.hash);

      case ExternalAddress():
        writeUint(BigInt.one, 2); // External
        writeUint(BigInt.from(address.bits), 9);
        writeUint(address.value, address.bits);
    }
  }

  /// Returns BitString with 0 offset out of a Uint8List, passed upon creation of BitBuilder instance
  BitString build() {
    return BitString(_list, 0, _length);
  }

  /// Returns Uint8List if it's aligned to bytes, throws otherwise
  Uint8List list() {
    if (_length % 8 != 0) {
      throw 'BitBuilder is not aligned to bytes';
    }
    return _list.sublist(0, _length ~/ 8);
  }
}
