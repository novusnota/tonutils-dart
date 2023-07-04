import 'dart:typed_data';

import '../address/api.dart' show Address;
import '../bitstring/api.dart' show BitString, BitBuilder;
import '../dictionary/api.dart'
    show DictionaryKeyType, DictionaryKey, DictionaryValue, Dictionary;
import 'api.dart' show Cell, Slice;
import 'utils/api.dart' show writeString;

/// Returns a new Builder for Cells
Builder beginCell() => Builder();

/// Writable type
abstract interface class Writable {
  // NOTE: consider removing interface keyword
  void writeTo(Builder builder);
}

/// Builder for Cells
class Builder {
  final BitBuilder _bits;
  final List<Cell> _refs;

  Builder()
      : _bits = BitBuilder(),
        _refs = <Cell>[];

  /// Returns number of bits written so far
  int get bits => _bits.length;

  /// Returns number of references written so far
  int get refs => _refs.length;

  /// Returns number of available bits
  int get availableBits => 1023 - bits;

  /// Returns number of available bits
  int get availableRefs => 4 - refs;

  /// Returns back this Builder, and writes a single bit into it
  Builder storeBit(int bit) {
    _bits.writeBit(bit);

    return this;
  }

  /// Returns back this Builder, and writes a bool as a single bit into it
  Builder storeBool(bool bbit) {
    _bits.writeBit(bbit == true ? 1 : 0);

    return this;
  }

  /// Returns back this Builder, and writes bits from a BitString into it
  Builder storeBits(BitString src) {
    _bits.writeBits(src);

    return this;
  }

  /// Returns back this Builder, and writes bytes from a Uint8List into it
  Builder storeList(Uint8List src, [int? bytes]) {
    if (bytes != null) {
      if (src.length != bytes) {
        throw 'Uint8List length ${src.length} is not equal to $bytes';
      }
    }
    _bits.writeList(
        src); // NOTE: this doesn't yet uses bytes length, apart from checking before
    return this;
  }

  /// Returns back this Builder, and writes 0 if Uint8List wasn't passed or 1 and Uint8List values otherwise
  Builder storeMaybeList(Uint8List? src, [int? bytes]) {
    if (src != null) {
      storeBit(1);
      storeList(src, bytes);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes another Builder in
  Builder storeBuilder(Builder src) {
    return storeSlice(src.endCell().beginParse());
  }

  /// Returns back this Builder, and writes 0 if Builder wasn't passed or 1 and Builder otherwise
  Builder storeMaybeBuilder([Builder? src]) {
    if (src != null) {
      storeBit(1);
      storeBuilder(src);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes a given amount of coins in
  Builder storeCoins(BigInt amount) {
    _bits.writeCoins(amount);
    return this;
  }

  /// Returns back this Builder, and writes 0 if coins amount wasn't passed or 1 and coins amount otherwise
  Builder storeMaybeCoins(BigInt? amount) {
    if (amount != null) {
      storeBit(1);
      storeCoins(amount);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes a [dict], [key] and [value] in if they're passed or 0 bit otherwise
  Builder storeDictionary<K extends DictionaryKeyType, V>([
    Dictionary<K, V>? dict,
    DictionaryKey<K>? key,
    DictionaryValue<V>? value,
  ]) {
    if (dict != null) {
      dict.store(this, key, value);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and directly writes a [dict], and additionally a [key] and a [value], if they were passed as well
  ///
  /// Throws 'Cannot store empty dictionary directly' if Dictionary is empty
  Builder storeDictionaryDirect<K extends DictionaryKeyType, V>(
    Dictionary<K, V> dict, [
    DictionaryKey<K>? key,
    DictionaryValue<V>? value,
  ]) {
    dict.storeDirect(this, key, value);
    return this;
  }

  /// Returns back this Builder, and writes Cell or Builder ref as a new reference
  Builder storeRef(dynamic ref) {
    // NOTE consider adding a union type CellBuilder for the ref

    if (_refs.length >= 4) {
      throw 'Too many references, can not add a new one!';
    }

    if (ref is Cell) {
      _refs.add(ref);
    } else if (ref is Builder) {
      _refs.add(ref.endCell());
    } else {
      throw 'Expected a Cell or a Builder, but got ${ref.runtimeType}';
    }

    return this;
  }

  /// Returns back this Builder, and writes 0 if ref wasn't passed or 1 and a new reference to ref (Cell or Builder) otherwise
  Builder storeMaybeRef([dynamic ref]) {
    // NOTE consider adding a union type CellBuilder for the ref
    if (ref != null) {
      storeBit(1);
      storeRef(ref);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes a Slice in
  Builder storeSlice(Slice src) {
    var c = src.clone();
    if (c.remainingBits > 0) {
      storeBits(c.loadBits(c.remainingBits));
    }
    while (c.remainingRefs > 0) {
      storeRef(c.loadRef());
    }
    return this;
  }

  /// Returns back this Builder, and writes 0 if Slice wasn't passed or 1 and Slice otherwise
  Builder storeMaybeSlice([Slice? src]) {
    if (src != null) {
      storeBit(1);
      storeSlice(src);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes String value in a reference
  Builder storeStringRefTail(String src) {
    storeRef(beginCell().storeStringTail(src));
    return this;
  }

  /// Returns back this Builder, and writes 0 if String wasn't passed or 1 and String value in a reference otherwise
  Builder storeMaybeStringRefTail([String? src]) {
    if (src != null) {
      storeBit(1);
      storeStringRefTail(src);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes String value in
  Builder storeStringTail(String src) {
    writeString(src, this);
    return this;
  }

  /// Returns back this Builder, and writes 0 if String wasn't passed or 1 and String otherwise
  Builder storeMaybeStringTail([String? src]) {
    if (src != null) {
      storeBit(1);
      writeString(src, this);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes uint value from a BigInt
  Builder storeUint(BigInt value, int bits) {
    _bits.writeUint(value, bits);
    return this;
  }

  /// Returns back this Builder, and writes 0 if uint value wasn't passed or 1 and uint as bit values otherwise
  Builder storeMaybeUint(BigInt? value, int bits) {
    if (value != null) {
      storeBit(1);
      storeUint(value, bits);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes int value from a BigInt
  Builder storeInt(BigInt value, int bits) {
    _bits.writeInt(value, bits);
    return this;
  }

  /// Returns back this Builder, and writes 0 if int value wasn't passed or 1 and int as bit values otherwise
  Builder storeMaybeInt(BigInt? value, int bits) {
    if (value != null) {
      storeBit(1);
      storeInt(value, bits);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes var int value in
  Builder storeVarInt(BigInt value, int bits) {
    _bits.writeVarInt(value, bits);
    return this;
  }

  /// Returns back this Builder, and writes 0 if var int wasn't passed or 1 and var int as bit values otherwise
  Builder storeMaybeVarInt(BigInt? value, int bits) {
    if (value != null) {
      storeBit(1);
      storeVarInt(value, bits);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes var uint value in
  Builder storeVarUint(BigInt value, int bits) {
    _bits.writeVarUint(value, bits);
    return this;
  }

  /// Returns back this Builder, and writes 0 if var uint wasn't passed or 1 and var uint as bit values otherwise
  Builder storeMaybeVarUint(BigInt? value, int bits) {
    if (value != null) {
      storeBit(1);
      storeVarUint(value, bits);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes a Writable or a function of Builder in
  Builder storeWritable(dynamic writer) {
    if (writer is Writable) {
      writer.writeTo(this);
    } else if (writer is Function) {
      writer(this);
    } else {
      throw 'Expected a Function of Builder or a Writable, got ${writer.runtimeType}';
    }
    return this;
  }

  /// Returns back this Builder, and writes 0 if Writeable wasn't passed or 1 and Writeable as bit values otherwise
  Builder storeMaybeWritable([dynamic writer]) {
    if (writer != null) {
      storeBit(1);
      storeWritable(writer!);
    } else {
      storeBit(0);
    }
    return this;
  }

  /// Returns back this Builder, and writes a Writable or a function of Builder in
  Builder store(dynamic writer) {
    storeWritable(writer);
    return this;
  }

  /// Returns back this Builder, and writes an address in
  Builder storeAddress(Address? address) {
    _bits.writeAddress(address);
    return this;
  }

  /// Returns a new complete Cell
  Cell endCell() {
    return Cell(
      bits: _bits.build(),
      refs: _refs,
    );
  }

  /// Returns a new Cell out of this Builder
  Cell asCell() {
    return endCell();
  }

  /// Returns a new Slice out of this Builder
  Slice asSlice() {
    return endCell().beginParse();
  }
}
