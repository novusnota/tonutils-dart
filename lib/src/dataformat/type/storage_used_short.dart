import '../cell/api.dart' show Builder, Slice;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L225
// storage_used_short$_ cells:(VarUInteger 7)
//  bits:(VarUInteger 7) = StorageUsedShort;

/// ```dart
/// ({
///   BigInt cells,
///   BigInt bits,
/// })
/// ```
class StorageUsedShort {
  BigInt cells;
  BigInt bits;

  StorageUsedShort({
    required this.cells,
    required this.bits,
  });
}

StorageUsedShort loadStorageUsedShort(Slice slice) {
  var cells = slice.loadVarUintBig(3);
  var bits = slice.loadVarUintBig(3);

  return StorageUsedShort(cells: cells, bits: bits);
}

void Function(Builder builder) storeStorageUsedShort(StorageUsedShort src) {
  return (Builder builder) {
    builder.storeVarUint(src.cells, 3);
    builder.storeVarUint(src.bits, 3);
  };
}
