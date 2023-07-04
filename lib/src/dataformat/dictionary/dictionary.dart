import 'dart:typed_data';

import '../address/api.dart' show Address, InternalAddress;
import '../cell/api.dart' show beginCell, Builder, Cell, Slice;
import 'utils/api.dart'
    show deserializeInternalKey, serializeInternalKey, parseDict, serializeDict;

/// Either of: DktInternalAddress, DktInt, DktBigInt or DktUint8List
///
/// Used in DictionaryKey
sealed class DictionaryKeyType {
  dynamic get key;
}

/// Wrapper around InternalAddress, has only one field: InternalAddress key
class DktInternalAddress extends DictionaryKeyType {
  @override
  InternalAddress key;

  DktInternalAddress(this.key);
}

/// Wrapper around int, has only one field: int key
class DktInt extends DictionaryKeyType {
  @override
  int key;

  DktInt(this.key);
}

/// Wrapper around BigInt, has only one field: BigInt key
class DktBigInt extends DictionaryKeyType {
  @override
  BigInt key;

  DktBigInt(this.key);
}

/// Wrapper around Uint8List, has only one field: Uint8List key
class DktUint8List extends DictionaryKeyType {
  @override
  Uint8List key;

  DktUint8List(this.key);
}

/// ```dart
/// ({
///   int bits,
///   BigInt Function(K src) serialize,
///   K Function(BigInt src) parse,
/// })
/// ```
class DictionaryKey<K extends DictionaryKeyType> {
  int bits;
  BigInt Function(K src) serialize;
  K Function(BigInt src) parse;

  DictionaryKey({
    required this.bits,
    required this.serialize,
    required this.parse,
  });
}

/// ```dart
/// ({
///   void Function(V src, Builder builder) serialize,
///   V Function(Slice src) parse,
/// })
/// ```
class DictionaryValue<V> {
  final void Function(V src, Builder builder) serialize;
  final V Function(Slice src) parse;

  DictionaryValue({
    required this.serialize,
    required this.parse,
  });
}

/// Dictionary/HashMap
class Dictionary<K extends DictionaryKeyType, V> {
  /// Returns a standard InternalAddress key, wrapped in DktInternalAddress
  static DictionaryKey<DktInternalAddress> createKeyAddress() {
    return DictionaryKey(
      bits: 267,
      serialize: (src) {
        return beginCell()
            .storeAddress(src.key)
            .endCell()
            .beginParse()
            .preloadUintBig(267);
      },
      parse: (src) {
        return DktInternalAddress(beginCell()
            .storeUint(src, 267)
            .endCell()
            .beginParse()
            .loadInternalAddress());
      },
    );
  }

  /// Returns a standard BigInt key, wrapped in DktBigInt
  static DictionaryKey<DktBigInt> createKeyBigInt(int bits) {
    return DictionaryKey(
      bits: bits,
      serialize: (src) {
        return beginCell()
            .storeInt(src.key, bits)
            .endCell()
            .beginParse()
            .loadUintBig(bits);
      },
      parse: (src) {
        return DktBigInt(beginCell()
            .storeUint(src, bits)
            .endCell()
            .beginParse()
            .loadIntBig(bits));
      },
    );
  }

  /// Returns a standard int key, wrapped in DktInt
  static DictionaryKey<DktInt> createKeyInt(int bits) {
    return DictionaryKey(
      bits: bits,
      serialize: (src) {
        return beginCell()
            .storeInt(BigInt.from(src.key), bits)
            .endCell()
            .beginParse()
            .loadUintBig(bits);
      },
      parse: (src) {
        return DktInt(beginCell()
            .storeUint(src, bits)
            .endCell()
            .beginParse()
            .loadInt(bits));
      },
    );
  }

  /// Returns a standard BigInt key, wrapped in DktBigInt
  ///
  /// Throws 'Key is negative...' if the [src.key] < 0
  static DictionaryKey<DktBigInt> createKeyBigUint(int bits) {
    return DictionaryKey(
      bits: bits,
      serialize: (src) {
        if (src.key.isNegative) {
          throw 'Key is negative: ${src.key}';
        }
        return beginCell()
            .storeInt(src.key, bits)
            .endCell()
            .beginParse()
            .loadUintBig(bits);
      },
      parse: (src) {
        return DktBigInt(BigInt.from(beginCell()
            .storeUint(src, bits)
            .endCell()
            .beginParse()
            .loadInt(bits)));
      },
    );
  }

  /// Returns a standard int key, wrapped in DktInt
  ///
  /// Throws 'Key is negative...' if the [src.key] < 0
  static DictionaryKey<DktInt> createKeyUint(int bits) {
    return DictionaryKey(
      bits: bits,
      serialize: (src) {
        if (src.key.isNegative) {
          throw 'Key is negative: ${src.key}';
        }
        return beginCell()
            .storeUint(BigInt.from(src.key), bits)
            .endCell()
            .beginParse()
            .loadUintBig(bits);
      },
      parse: (src) {
        return DktInt(beginCell()
            .storeUint(src, bits)
            .endCell()
            .beginParse()
            .loadUint(bits));
      },
    );
  }

  /// Returns a standard Uint8List key, wrapped in DktUint8List
  static DictionaryKey<DktUint8List> createKeyList(int nbytes) {
    return DictionaryKey(
      bits: nbytes * 8,
      serialize: (src) {
        return beginCell()
            .storeList(src.key)
            .endCell()
            .beginParse()
            .loadUintBig(nbytes * 8);
      },
      parse: (src) {
        return DktUint8List(beginCell()
            .storeUint(src, nbytes * 8)
            .endCell()
            .beginParse()
            .loadList(nbytes));
      },
    );
  }

  /// Returns a standard int value
  static DictionaryValue<int> createValueInt(int bits) {
    return DictionaryValue(
      serialize: (src, builder) {
        builder.storeInt(BigInt.from(src), bits);
      },
      parse: (src) {
        return src.loadInt(bits);
      },
    );
  }

  /// Returns a standard BigInt value
  static DictionaryValue<BigInt> createValueBigInt(int bits) {
    return DictionaryValue(
      serialize: (src, builder) {
        builder.storeInt(src, bits);
      },
      parse: (src) {
        return src.loadIntBig(bits);
      },
    );
  }

  /// Returns a standard BigInt value
  static DictionaryValue<BigInt> createValueBigVarInt(int bits) {
    return DictionaryValue(
      serialize: (src, builder) {
        builder.storeVarInt(src, bits);
      },
      parse: (src) {
        return src.loadVarIntBig(bits);
      },
    );
  }

  /// Returns a standard BigInt value
  static DictionaryValue<BigInt> createValueBigVarUint(int bits) {
    return DictionaryValue(
      serialize: (src, builder) {
        builder.storeVarUint(src, bits);
      },
      parse: (src) {
        return src.loadVarUintBig(bits);
      },
    );
  }

  /// Returns a standard int value
  static DictionaryValue<int> createValueUint(int bits) {
    return DictionaryValue(
      serialize: (src, builder) {
        builder.storeUint(BigInt.from(src), bits);
      },
      parse: (src) {
        return src.loadUint(bits);
      },
    );
  }

  /// Returns a standard BigInt value
  static DictionaryValue<BigInt> createValueBigUint(int bits) {
    return DictionaryValue(
      serialize: (src, builder) {
        builder.storeUint(src, bits);
      },
      parse: (src) {
        return src.loadUintBig(bits);
      },
    );
  }

  /// Returns a standard bool value
  static DictionaryValue<bool> createValueBool() {
    return DictionaryValue(
      serialize: (src, builder) {
        builder.storeBit(src == true ? 1 : 0);
      },
      parse: (src) {
        return src.loadBit() == 0 ? false : true;
      },
    );
  }

  /// Returns a standard Address value, operates mostly on InternalAddress
  static DictionaryValue<Address> createValueAddress() {
    return DictionaryValue(
      serialize: (src, builder) {
        builder.storeAddress(src);
      },
      parse: (src) {
        return src.loadInternalAddress();
      },
    );
  }

  /// Returns a standard Cell value
  static DictionaryValue<Cell> createValueCell() {
    return DictionaryValue(
      serialize: (src, builder) {
        builder.storeRef(src);
      },
      parse: (src) {
        return src.loadRef();
      },
    );
  }

  /// Returns a standard Uint8List value
  ///
  /// Throws 'Invalid buffer size...' if [src.length] != [size]
  static DictionaryValue<Uint8List> createValueList(int size) {
    return DictionaryValue(
      serialize: (src, builder) {
        if (src.length != size) {
          throw 'Invalid buffer size, expected $size, got ${src.length}';
        }
        builder.storeList(src);
      },
      parse: (src) {
        return src.loadList(size);
      },
    );
  }

  /// Returns a standard Dictionary<K, V>, where K extends DictionaryKeyType
  static DictionaryValue<Dictionary<K, V>>
      createValueDictionary<K extends DictionaryKeyType, V>(
    DictionaryKey<K> key,
    DictionaryValue<V> value,
  ) {
    return DictionaryValue(
      serialize: (src, builder) {
        src.store(builder);
      },
      parse: (src) {
        return Dictionary.load(key, value, src);
      },
    );
  }

  /// Returns a new Dictionary with an empty map of values
  static Dictionary<K, V> empty<K extends DictionaryKeyType, V>([
    DictionaryKey<K>? key,
    DictionaryValue<V>? value,
  ]) {
    if (key != null && value != null) {
      return Dictionary<K, V>(<String, V>{}, key, value);
    } else {
      return Dictionary<K, V>(<String, V>{}, null, null);
    }
  }

  /// Returns a new Dictionary from a Slice
  static Dictionary<K, V> load<K extends DictionaryKeyType, V>(
    DictionaryKey<K> key,
    DictionaryValue<V> value,
    Slice sc,
  ) {
    var slice = sc; // NOTE .clone()?
    var cell = slice.loadMaybeRef();

    if (cell != null && cell.isExotic == false) {
      return Dictionary.loadDirect<K, V>(key, value, cell.beginParse());
    } else {
      return Dictionary.empty<K, V>(key, value);
    }
  }

  /// Returns a new Dictionary from a Cell
  static Dictionary<K, V> loadCell<K extends DictionaryKeyType, V>(
    DictionaryKey<K> key,
    DictionaryValue<V> value,
    Cell cell,
  ) {
    var slice = cell.beginParse();
    return load<K, V>(key, value, slice);
  }

  /// Returns a new Dictionary from a Slice directly, without going to the reference
  ///
  /// It's a low-level method for rare dictionaries from system contracts
  static Dictionary<K, V> loadDirect<K extends DictionaryKeyType, V>(
    DictionaryKey<K> key,
    DictionaryValue<V> value,
    Slice sc,
  ) {
    var slice = sc; // NOTE .clone()?
    var values = parseDict(slice, key.bits, value.parse);
    var prepared = <String, V>{};

    for (final entry in values.entries) {
      var ik = serializeInternalKey(key.parse(entry.key));
      prepared[ik] = entry.value;
    }

    return Dictionary(prepared, key, value);
  }

  /// Returns a new Dictionary from a Cell directly, without going to the reference
  ///
  /// It's a low-level method for rare dictionaries from system contracts
  static Dictionary<K, V> loadDirectCell<K extends DictionaryKeyType, V>(
    DictionaryKey<K> key,
    DictionaryValue<V> value,
    Cell cell,
  ) {
    var slice = cell.beginParse();
    return loadDirect(key, value, slice);
  }

  final Map<String, V> _map;
  final DictionaryKey<K>? _key;
  final DictionaryValue<V>? _value;

  Dictionary(this._map, this._key, this._value);

  int get length {
    return this._map.length;
  }

  V? get(K key) {
    var ik = serializeInternalKey(key);

    return _map.containsKey(ik) ? _map[ik] : null;
  }

  bool has(K key) {
    var ik = serializeInternalKey(key);

    return _map.containsKey(ik);
  }

  Dictionary<K, V> set(K key, V value) {
    var ik = serializeInternalKey(key);
    _map[ik] = value;

    return this;
  }

  V? delete(K key) {
    var ik = serializeInternalKey(key);

    return _map.remove(ik);
  }

  void clear() {
    _map.clear();
  }

  /// Returns a iterator over mapped entries with deserialized internal keys from Strings to DictionaryKeyType sub-types
  Iterable<MapEntry<K, V>> get entries sync* {
    for (final entry in _map.entries) {
      final key = deserializeInternalKey(entry.key) as K;
      yield MapEntry(key, entry.value);
    }
  }

  /// Returns a new list out of deserialized internal keys from Strings to DictionaryKeyType sub-types
  List<K> get keys {
    return List.of(_map.keys.map((e) => deserializeInternalKey(e) as K));
  }

  /// Returns a new list out of values
  List<V> get values {
    return List.of(_map.values);
  }

  /// Returns back a Builder [builder], and stores there 0 if Dictionary is empty, 1 and a reference otherwise
  ///
  /// Throws 'Key/Value serializer is not defined' if correspondingly neither [key]/[value] nor internal _key/_value are defined and not null
  Builder store(
    Builder builder, [
    DictionaryKey<K>? key,
    DictionaryValue<V>? value,
  ]) {
    if (_map.isEmpty) {
      builder.storeBit(0);
      return builder;
    }
    var resolvedKey = key ?? _key;
    var resolvedValue = value ?? _value;

    if (resolvedKey == null) {
      throw 'Key serializer is not defined';
    }
    if (resolvedValue == null) {
      throw 'Value serializer is not defined';
    }

    var prepared = <BigInt, V>{};
    for (final entry in _map.entries) {
      var sk = resolvedKey.serialize(deserializeInternalKey(entry.key) as K);
      prepared[sk] = entry.value;
    }

    builder.storeBit(1);
    var dd = beginCell();
    serializeDict(prepared, resolvedKey.bits, resolvedValue.serialize, dd);
    builder.storeRef(dd.endCell());

    return builder;
  }

  /// Returns nothing, and directly stores the dictionary in a [builder]
  ///
  /// Throws 'Cannot store empty dictionary directly' if Dictionary is empty
  /// Throws 'Key/Value serializer is not defined' if correspondingly neither [key]/[value] nor internal _key/_value are defined and not null
  void storeDirect(
    Builder builder, [
    DictionaryKey<K>? key,
    DictionaryValue<V>? value,
  ]) {
    if (_map.isEmpty) {
      throw 'Cannot store empty dictionary directly';
    }

    var resolvedKey = key ?? _key;
    var resolvedValue = value ?? _value;

    if (resolvedKey == null) {
      throw 'Key serializer is not defined';
    }
    if (resolvedValue == null) {
      throw 'Value serializer is not defined';
    }

    var prepared = <BigInt, V>{};
    for (final entry in _map.entries) {
      var sk = resolvedKey.serialize(deserializeInternalKey(entry.key) as K);
      prepared[sk] = entry.value;
    }

    serializeDict(prepared, resolvedKey.bits, resolvedValue.serialize, builder);
  }
}
