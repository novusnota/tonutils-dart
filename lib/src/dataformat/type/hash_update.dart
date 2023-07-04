import 'dart:typed_data';

import '../cell/api.dart' show Builder, Slice;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L273
// update_hashes#72 {X:Type} old_hash:bits256 new_hash:bits256
//  = HASH_UPDATE X;

/// ```dart
/// ({
///   Uint8List oldHash,
///   Uint8List newHash,
/// })
/// ```
class HashUpdate {
  Uint8List oldHash;
  Uint8List newHash;

  HashUpdate({
    required this.oldHash,
    required this.newHash,
  });
}

/// Throws 'Invalid data' if the loaded uint of 8 bits != 0x72
loadHashUpdate(Slice slice) {
  if (slice.loadUint(8) != 0x72) {
    throw 'Invalid data';
  }
  final oldHash = slice.loadList(32);
  final newHash = slice.loadList(32);

  return HashUpdate(oldHash: oldHash, newHash: newHash);
}

void Function(Builder builder) storeHashUpdate(HashUpdate src) {
  return (Builder builder) {
    builder.storeUint(BigInt.from(0x72), 8);
    builder.storeList(src.oldHash);
    builder.storeList(src.newHash);
  };
}
