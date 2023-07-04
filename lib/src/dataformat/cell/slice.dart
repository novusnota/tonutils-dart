import 'dart:typed_data';

import '../address/api.dart' show Address, InternalAddress, ExternalAddress;
import '../bitstring/api.dart' show BitString, BitReader;
import '../dictionary/api.dart'
    show DictionaryKeyType, DictionaryKey, DictionaryValue, Dictionary;
import 'api.dart' show Builder, Cell, beginCell, readString;

/// Slice is used for reading Cell data
class Slice {
  final BitReader _reader;
  final List<Cell> _refs;
  int _refsOffset;

  Slice(BitReader reader, List<Cell> refs)
      : _reader = reader.clone(),
        _refs = List.of(refs),
        _refsOffset = 0;

  /// Returns number of remaining bits
  int get remainingBits => _reader.remaining;

  /// Returns an offset of number of bits
  int get offsetBits => _reader.offset;

  /// Returns number of remaining references
  int get remainingRefs => _refs.length - _refsOffset;

  /// Returns and offset of references
  int get offsetRefs => _refsOffset;

  /// Returns back this Slice, and skips n bits
  Slice skip(int n) {
    _reader.skip(n);
    return this;
  }

  /// Returns a single bit at current BitReaders offset, and moves that offset one position
  int loadBit() {
    return _reader.loadBit();
  }

  /// Returns a single bit at current BitReaders offset
  int preloadBit() {
    return _reader.preloadBit();
  }

  /// Returns a bool depending on the bit value read in loadBit(): true if bit was 1, false otherwise
  bool loadBool() {
    return loadBit() == 1 ? true : false;
  }

  /// Returns a bool value of loadBoolean() or null, depending on loadBit's value
  bool? loadMaybeBool() {
    if (loadBit() == 1) {
      return loadBool();
    } else {
      return null;
    }
  }

  /// Returns a new BitString of n bits from internal BitReader at its current offset, and moves that offset n positions
  BitString loadBits(int n) {
    return _reader.loadBits(n);
  }

  /// Returns a new BitString of n bits from internal BitReader at its current offset
  BitString preloadBits(int n) {
    return _reader.preloadBits(n);
  }

  /// Returns a uint of n bits from internal BitReader at its current offset, and moves that offset n positions
  int loadUint(int n) {
    return _reader.loadUint(n);
  }

  /// Returns a uint of n bits from internal BitReader at its current offset
  int preloadUint(int n) {
    return _reader.preloadUint(n);
  }

  /// Returns a uint of n bits as a BigInt from internal BitReader at its current offset, and moves that offset n positions
  BigInt loadUintBig(int n) {
    return _reader.loadUintBig(n);
  }

  /// Returns a uint of n bits as a BigInt from internal BitReader at its current offset
  BigInt preloadUintBig(int n) {
    return _reader.preloadUintBig(n);
  }

  /// Returns a uint of n bits or null from internal BitReader at its current offset, and moves that offset n positions. Depends on loadBit()
  int? loadMaybeUint(int n) {
    if (loadBit() == 1) {
      return _reader.loadUint(n);
    } else {
      return null;
    }
  }

  /// Returns a uint of n bits as BigInt or null from internal BitReader at its current offset, and moves that offset n positions. Depends on loadBit() value
  BigInt? loadMaybeUintBig(int n) {
    if (loadBit() == 1) {
      return _reader.loadUintBig(n);
    } else {
      return null;
    }
  }

  /// Returns a int of n bits from internal BitReader at its current offset, and moves that offset n positions
  int loadInt(int n) {
    return _reader.loadInt(n);
  }

  /// Returns a int of n bits from internal BitReader at its current offset
  int preloadInt(int n) {
    return _reader.preloadInt(n);
  }

  /// Returns a int of n bits as a BigInt from internal BitReader at its current offset, and moves that offset n positions
  BigInt loadIntBig(int n) {
    return _reader.loadIntBig(n);
  }

  /// Returns a int of n bits as a BigInt from internal BitReader at its current offset
  BigInt preloadIntBig(int n) {
    return _reader.preloadIntBig(n);
  }

  /// Returns a int of n bits or null from internal BitReader at its current offset, and moves that offset n positions. Depends on loadBit() value
  int? loadMaybeInt(int n) {
    if (loadBit() != 0) {
      return loadInt(n);
    } else {
      return null;
    }
  }

  /// Returns a int of n bits as BigInt or null from internal BitReader at its current offset, and moves that offset n positions. Depends on loadBit() value
  BigInt? loadMaybeIntBig(int n) {
    if (loadBit() != 0) {
      return loadIntBig(n);
    } else {
      return null;
    }
  }

  /// Returns a var uint of n bits from internal BitReader at its current offset, and moves that offset n positions
  int loadVarUint(int n) {
    return _reader.loadVarUint(n);
  }

  /// Returns a var uint of n bits from internal BitReader at its current offset
  int preloadVarUint(int n) {
    return _reader.preloadVarUint(n);
  }

  /// Returns a var uint of n bits as a BigInt from internal BitReader at its current offset, and moves that offset n positions
  BigInt loadVarUintBig(int n) {
    return _reader.loadVarUintBig(n);
  }

  /// Returns a var uint of n bits as a BigInt from internal BitReader at its current offset
  BigInt preloadVarUintBig(int n) {
    return _reader.preloadVarUintBig(n);
  }

  /// Returns a var int of n bits from internal BitReader at its current offset, and moves that offset n positions
  int loadVarInt(int n) {
    return _reader.loadVarInt(n);
  }

  /// Returns a var int of n bits from internal BitReader at its current offset
  int preloadVarInt(int n) {
    return _reader.preloadVarInt(n);
  }

  /// Returns a var int of n bits as a BigInt from internal BitReader at its current offset, and moves that offset n positions
  BigInt loadVarIntBig(int n) {
    return _reader.loadVarIntBig(n);
  }

  /// Returns a var int of n bits as a BigInt from internal BitReader at its current offset
  BigInt preloadVarIntBig(int n) {
    return _reader.preloadVarIntBig(n);
  }

  /// Returns coins value as a BigInt from internal BitReader at its current offset, and moves that offset some number of positions
  BigInt loadCoins() {
    return _reader.loadCoins();
  }

  /// Returns coins value as a BigInt from internal BitReader at its current offset
  BigInt preloadCoins() {
    return _reader.preloadCoins();
  }

  /// Returns a coins value as a BigInt or null from internal BitReader at its current offset, and moves that offset some number of positions. Depends on BitReaders loadBit() value
  BigInt? loadMaybeCoins() {
    if (_reader.loadBit() == 1) {
      return _reader.loadCoins();
    } else {
      return null;
    }
  }

  /// Returns an InternalAddress from internal BitReader at its current offset
  InternalAddress loadInternalAddress() {
    return _reader.loadInternalAddress();
  }

  /// Returns an InternalAddress or null from internal BitReader at its current offset, and moves that offset two positions in case of type == 0
  InternalAddress? loadInternalAddressOrNull() {
    return _reader.loadInternalAddressOrNull();
  }

  /// Returns an ExternalAddress or null from internal BitReader at its current offset
  ExternalAddress loadExternalAddress() {
    return _reader.loadExternalAddress();
  }

  /// Returns an ExternalAddress or null from internal BitReader at its current offset, and moves that offset two positions in case of type == 0
  ExternalAddress? loadExternalAddressOrNull() {
    return _reader.loadExternalAddressOrNull();
  }

  /// Returns an InternalAddress or ExternalAddress or null from internal BitReader at its current offset, and moves that offset two positions in case of type == 0
  Address? loadAnyAddressOrNull() {
    return _reader.loadAnyAddressOrNull();
  }

  /// Returns a Cell from the current refs offset, and moves this offset one position
  Cell loadRef() {
    if (_refsOffset >= _refs.length) {
      throw 'No more references!';
    }
    return _refs[_refsOffset++];
  }

  /// Returns a Cell from the current refs offset
  Cell preloadRef() {
    if (_refsOffset >= _refs.length) {
      throw 'No more references!';
    }
    return _refs[_refsOffset];
  }

  /// Returns a Cell or null from the current refs offset, and moves this offset one position. Depends on loadBit() value
  Cell? loadMaybeRef() {
    if (loadBit() != 0) {
      return loadRef();
    } else {
      return null;
    }
  }

  /// Returns a Cell or null from the current refs offset. Depends on preloadBit() value
  Cell? preloadMaybeRef() {
    if (preloadBit() != 0) {
      return preloadRef();
    } else {
      return null;
    }
  }

  /// Returns a Uint8List of n bytes from internal BitReader at its current offset, and moves that offset n * 8 positions
  Uint8List loadList(int nbytes) {
    return _reader.loadList(nbytes);
  }

  /// Returns a Uint8List of n bytes from internal BitReader at its current offset
  Uint8List preloadList(int nbytes) {
    return _reader.preloadList(nbytes);
  }

  /// Returns a String out of this Slice
  String loadStringTail() {
    return readString(this);
  }

  /// Returns a String out of this Slice or null. Depends on loadBit()
  String? loadMaybeStringTail() {
    if (loadBit() != 0) {
      return readString(this);
    } else {
      return null;
    }
  }

  /// Returns a String from a reference at current refs offset, and moves this offset one position
  String loadStringRefTail() {
    return readString(loadRef().beginParse());
  }

  /// Returns a String or null from a reference at current refs offset, and moves this offset one position
  String? loadMaybeStringRefTail() {
    final ref = loadMaybeRef();
    if (ref != null) {
      return readString(ref.beginParse());
    } else {
      return null;
    }
  }

  /// Returns a Dictionary from [key] and [value] and this Slice
  Dictionary<K, V> loadDictionary<K extends DictionaryKeyType, V>(
    DictionaryKey<K> key,
    DictionaryValue<V> value,
  ) {
    return Dictionary.load(key, value, this);
  }

  /// Returns a Dictionary from [key] and [value], directly from the Slice at current refs offset
  Dictionary<K, V> loadDictionaryDirect<K extends DictionaryKeyType, V>(
    DictionaryKey<K> key,
    DictionaryValue<V> value,
  ) {
    return Dictionary.loadDirect(key, value, this);
  }

  /// Returns nothing, throws if the Slice is not empty and has some remaining bits or references in
  void endParse() {
    if (remainingBits > 0 || remainingRefs > 0) {
      throw 'Slice is not empty';
    }
  }

  /// Returns a Cell out of this Slice
  Cell asCell() {
    return beginCell().storeSlice(this).endCell();
  }

  /// Returns a Builder out of this Slice
  Builder asBuilder() {
    return beginCell().storeSlice(this);
  }

  /// Returns a deep copy of this Slice
  Slice clone({bool fromStart = false}) {
    if (fromStart == true) {
      var reader = _reader.clone();
      reader.reset();

      return Slice(reader, _refs);
    }

    var res = Slice(_reader, _refs);
    res._refsOffset = _refsOffset;
    return res;
  }

  /// Returns a String out of this Slice converted to a Cell
  @override
  String toString() {
    return asCell().toString();
  }
}
