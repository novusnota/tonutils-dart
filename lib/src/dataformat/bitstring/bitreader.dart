import 'dart:typed_data';

import '../address/api.dart' show Address, InternalAddress, ExternalAddress;
import 'bitstring.dart' show BitString;

/// Used for reading BitStrings
class BitReader {
  final BitString _bits;
  int _offset;
  final List<int> _checkpoints = <int>[];

  BitReader(this._bits, [this._offset = 0]);

  /// Returns offset in a source BitString
  int get offset {
    return _offset;
  }

  /// Returns number of bits remaining
  int get remaining {
    return _bits.length - _offset;
  }

  /// Returns nothing, resets offset to the beginning of latest checkpoint
  void reset() {
    if (_checkpoints.isNotEmpty) {
      _offset = _checkpoints.removeLast();
      return;
    }

    _offset = 0;
  }

  /// Returns nothing, adds a new checkpoint at current offset
  void save() {
    _checkpoints.add(_offset);
  }

  /// Returns nothing, skips n bits
  void skip(int n) {
    if (n < 0 || _offset + n > _bits.length) {
      throw 'Index ${_offset + n} is out of bounds of ${_bits.length}';
    }
    _offset += n;
  }

  /// Returns a copy of a BitReader, preserving current offset
  BitReader clone() {
    return BitReader(_bits, _offset);
  }

  /// Returns InternalAddress or ExternalAddress or null from current offset, and moves offset two positions in case of type == 0
  Address? loadAnyAddressOrNull() {
    var type = _preloadUintBig(_offset, 2).toInt();

    if (type == 0) {
      _offset += 2;
      return null;
    }

    if (type == 2) {
      return _loadInternalAddress();
    }

    if (type == 1) {
      return _loadExternalAddress();
    }

    if (type == 3) {
      throw 'Unsupported address type $type';
    }

    throw 'Invalid address type $type';
  }

  /// Returns a single bit and moves offset one position
  int loadBit() {
    var bit = _bits.at(_offset);
    _offset += 1;

    return bit;
  }

  /// Returns a BitString of n bits at the current offset, and moves offset n positions
  BitString loadBits(int n) {
    var bits = _bits.substring(_offset, n);
    _offset += n;

    return bits;
  }

  /// Returns var uint value (coins value) as a BigInt from current offset, and moves offset 4 + size * 8 positions
  BigInt loadCoins() {
    return loadVarUintBig(4);
  }

  /// Returns ExternalAddress or null from current offset
  ExternalAddress loadExternalAddress() {
    var type = _preloadUintBig(_offset, 2).toInt();

    if (type == 1) {
      return _loadExternalAddress();
    }

    throw 'Invalid address type $type';
  }

  /// Returns ExternalAddress or null from current offset, and moves offset two positions in case of type == 0
  ExternalAddress? loadExternalAddressOrNull() {
    var type = _preloadUintBig(_offset, 2).toInt();

    if (type == 0) {
      _offset += 2;
      return null;
    }

    if (type == 1) {
      return _loadExternalAddress();
    }

    throw 'Invalid address type $type';
  }

  /// Returns an int of n bits, and moves offset n positions
  int loadInt(int n) {
    return loadIntBig(n).toInt();
  }

  /// Returns an int value of n bits as a BigInt, and moves offset n positions
  BigInt loadIntBig(int n) {
    var r = _preloadIntBig(_offset, n);
    _offset += n;

    return r;
  }

  /// Returns InternalAddress from current offset
  InternalAddress loadInternalAddress() {
    var type = _preloadUintBig(_offset, 2).toInt();
    if (type == 2) {
      return _loadInternalAddress();
    }

    throw 'Invalid address type $type';
  }

  /// Returns InternalAddress or null from current offset, and moves offset two positions in case of type == 0
  InternalAddress? loadInternalAddressOrNull() {
    var type = _preloadUintBig(_offset, 2).toInt();

    if (type == 0) {
      _offset += 2;
      return null;
    }

    if (type == 2) {
      return _loadInternalAddress();
    }

    throw 'Invalid address type $type';
  }

  /// Returns a Uint8List of n bytes at the current offset, and moves offset n * 8 positions
  Uint8List loadList(int nbytes) {
    var b = _preloadList(_offset, nbytes);
    _offset += nbytes * 8;

    return b;
  }

  /// Returns padded BitString of n bits to make it byte aligned, and moves offset by n positions. Used in BoC.
  ///
  /// Throws 'Invalid number of bits...' if [n] % 8 != 0
  BitString loadPaddedBits(int n) {
    if (n % 8 != 0) {
      throw 'Invalid number of bits $n';
    }

    var length = n;
    while (true) {
      if (_bits.at(_offset + length - 1) != 0) {
        length -= 1;
        break;
      } else {
        length -= 1;
      }
    }

    var r = _bits.substring(_offset, length);
    _offset += n;

    return r;
  }

  /// Returns a uint of n bits, and moves offset n positions
  int loadUint(int n) {
    return loadUintBig(n).toInt();
  }

  /// Returns a uint value of n bits as a BigInt, and moves offset n positions
  BigInt loadUintBig(int n) {
    var r = preloadUintBig(n);
    _offset += n;

    return r;
  }

  /// Returns var int value of n bits from current offset, and moves offset n + size * 8 positions
  int loadVarInt(int n) {
    return loadVarIntBig(n).toInt();
  }

  /// Returns var int value of n bits as a BigInt from current offset, and moves offset n + size * 8 positions
  BigInt loadVarIntBig(int n) {
    var size = loadUint(n);
    return loadIntBig(size * 8);
  }

  /// Returns var uint value of n bits from current offset, and moves offset n + size * 8 positions
  int loadVarUint(int n) {
    return loadVarUintBig(n).toInt();
  }

  /// Returns var uint value of n bits as a BigInt from current offset, and moves offset n + size * 8 positions
  BigInt loadVarUintBig(int n) {
    var size = loadUint(n);
    return loadUintBig(size * 8);
  }

  /// Returns a single bit at the current offset
  int preloadBit() {
    return _bits.at(_offset);
  }

  /// Returns a BitString of n bits at the current offset
  BitString preloadBits(int n) {
    return _bits.substring(_offset, n);
  }

  /// Returns var uint value (coins value) as a BigInt from current offset
  BigInt preloadCoins() {
    return preloadVarUintBig(4);
  }

  /// Returns an int value of n bits
  int preloadInt(int n) {
    return _preloadIntBig(_offset, n).toInt();
  }

  /// Returns an int value of n bits as a BigInt
  BigInt preloadIntBig(int n) {
    return _preloadIntBig(_offset, n);
  }

  /// Returns a Uint8List of n bytes at the current offset
  Uint8List preloadList(int nbytes) {
    return _preloadList(_offset, nbytes);
  }

  /// Returns a uint value of n bits
  int preloadUint(int n) {
    return _preloadUintBig(_offset, n).toInt();
  }

  /// Returns a uint value of n bits as a BigInt
  BigInt preloadUintBig(int n) {
    return _preloadUintBig(_offset, n);
  }

  /// Returns var int value of n bits from current offset
  int preloadVarInt(int n) {
    return preloadVarIntBig(n).toInt();
  }

  /// Returns var int value of n bits as a BigInt from current offset
  BigInt preloadVarIntBig(int n) {
    var size = _preloadUintBig(_offset, n).toInt();
    return _preloadIntBig(_offset + n, size * 8);
  }

  /// Returns var uint value of n bits from current offset
  int preloadVarUint(int n) {
    return preloadVarUintBig(n).toInt();
  }

  /// Returns var uint value of n bits as a BigInt from current offset
  BigInt preloadVarUintBig(int n) {
    var size = _preloadUintBig(_offset, n).toInt();
    return _preloadUintBig(_offset + n, size * 8);
  }

  /// Returns ExternalAddress at current offset position, and moves offset 267 positions
  ExternalAddress _loadExternalAddress() {
    var type = _preloadUintBig(_offset, 2).toInt();
    if (type != 1) {
      throw 'Invalid address type $type';
    }

    var bits = _preloadUintBig(_offset + 2, 9).toInt();
    var value = _preloadUintBig(_offset + 11, bits);

    _offset += 11 + bits;

    return ExternalAddress(value, bits);
  }

  /// Returns InternalAddress at current offset position, and moves offset 267 positions
  InternalAddress _loadInternalAddress() {
    var type = _preloadUintBig(_offset, 2).toInt();
    if (type != 2) {
      throw 'Invalid address type $type';
    }

    if (_preloadUintBig(_offset + 2, 1) != BigInt.zero) {
      throw 'Invalid address';
    }

    var wc = _preloadIntBig(_offset + 3, 8);
    var hash = _preloadList(_offset + 11, 32);

    _offset += 267;

    return InternalAddress(wc, hash);
  }

  /// Returns an int value of n bits as a BigInt from a specified offset
  BigInt _preloadIntBig(int offset, int n) {
    if (n == 0) {
      return BigInt.zero;
    }
    var sign = _bits.at(offset);
    var res = BigInt.zero;

    for (var i = 0; i < n - 1; i += 1) {
      if (_bits.at(offset + 1 + i) != 0) {
        res += BigInt.one << (n - i - 1 - 1);
      }
    }

    if (sign != 0) {
      res -= BigInt.one << (n - 1);
    }
    return res;
  }

  /// Returns a Uint8List of nbytes from given offset
  Uint8List _preloadList(int offset, int nbytes) {
    var fastBuffer = _bits.sublist(offset, nbytes * 8);
    if (fastBuffer != null) {
      return fastBuffer;
    }

    var buf = Uint8List(nbytes);
    for (var i = 0; i < nbytes; i += 1) {
      buf[i] = _preloadUintBig(offset + i * 8, 8).toInt();
    }

    return buf;
  }

  /// Returns a uint value of n bits as a BigInt from a specified offset
  BigInt _preloadUintBig(int offset, int n) {
    if (n == 0) {
      return BigInt.zero;
    }
    var res = BigInt.zero;
    for (var i = 0; i < n; i += 1) {
      if (_bits.at(offset + i) != 0) {
        res += BigInt.one << (n - i - 1);
      }
    }
    return res;
  }
}
