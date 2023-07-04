import 'dart:typed_data';

import 'package:convert/convert.dart';

import '../../address/api.dart' show InternalAddress;
import '../api.dart'
    show DictionaryKeyType, DktBigInt, DktInt, DktInternalAddress, DktUint8List;

/// Returns a String from the internal [key]
///
/// Accepts wrappers of int, BigInt, InternalAddress, Uint8List — DktInt, DktBigInt, DktInternalAddress, DktUint8List correspondingly.
String serializeInternalKey(DictionaryKeyType key) {
  switch (key) {
    case DktInt():
      return 'n:${key.key.toRadixString(10)}';
    case DktBigInt():
      return 'b:${key.key.toRadixString(10)}';
    case DktInternalAddress():
      return 'a:${key.key.toString()}';
    case DktUint8List():
      return 'f:${hex.encode(key.key)}';
  }
}

/// Returns an internal key as either of: int, BigInt, InternalAddress, Uint8List. It's wrapped into a DictionaryKeyType sub-type: DktInt, DktBigInt, DktInternalAddress, DktUint8List correspondingly.
///
/// Throws 'Invalid key type...' if String [value] is serialized not from the types listed above
DictionaryKeyType deserializeInternalKey(String serializedKey) {
  var k = serializedKey.substring(0, 2);
  var v = serializedKey.substring(2);

  switch (k) {
    case 'n:':
      return DktInt(int.parse(v, radix: 10));
    case 'b:':
      return DktBigInt(BigInt.parse(v, radix: 10));
    case 'a:':
      return DktInternalAddress(InternalAddress.parse(v));
    case 'f:':
      return DktUint8List(Uint8List.fromList(hex.decode(v)));
    case _:
      throw 'Invalid key type: $k';
  }
}
