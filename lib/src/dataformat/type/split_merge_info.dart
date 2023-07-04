import '../cell/api.dart' show Builder, Slice;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L339
// split_merge_info$_ cur_shard_pfx_len:(## 6)
//   acc_split_depth:(## 6) this_addr:bits256 sibling_addr:bits256
//   = SplitMergeInfo;

class SplitMergeInfo {
  int currentShardPrefixLength;
  int accountSplitDepth;
  BigInt thisAddress;
  BigInt siblingAddress;

  SplitMergeInfo({
    required this.currentShardPrefixLength,
    required this.accountSplitDepth,
    required this.thisAddress,
    required this.siblingAddress,
  });
}

SplitMergeInfo loadSplitMergeInfo(Slice slice) {
  var currentShardPrefixLength = slice.loadUint(6);
  var accountSplitDepth = slice.loadUint(6);
  var thisAddress = slice.loadUintBig(256);
  var siblingAddress = slice.loadUintBig(256);

  return SplitMergeInfo(
    currentShardPrefixLength: currentShardPrefixLength,
    accountSplitDepth: accountSplitDepth,
    thisAddress: thisAddress,
    siblingAddress: siblingAddress,
  );
}

void Function(Builder builder) storeSplitMergeInfo(SplitMergeInfo src) {
  return (Builder builder) {
    builder.storeUint(BigInt.from(src.currentShardPrefixLength), 6);
    builder.storeUint(BigInt.from(src.accountSplitDepth), 6);
    builder.storeUint(src.thisAddress, 256);
    builder.storeUint(src.siblingAddress, 256);
  };
}
