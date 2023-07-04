import '../cell/api.dart' show Builder, Slice;
import 'api.dart'
    show AccountStatusChange, loadAccountStatusChange, storeAccountStatusChange;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L284
// tr_phase_storage$_ storage_fees_collected:Grams
//   storage_fees_due:(Maybe Grams)
//   status_change:AccStatusChange
//   = TrStoragePhase;

/// ```dart
/// ({
///   BigInt storageFeesCollected,
///   BigInt? storageFeesDue,
///   AccountStatusChange statusChange,
/// })
/// ```
class TransactionStoragePhase {
  final BigInt storageFeesCollected;
  BigInt? storageFeesDue;
  final AccountStatusChange statusChange;

  TransactionStoragePhase({
    required this.storageFeesCollected,
    this.storageFeesDue,
    required this.statusChange,
  });
}

TransactionStoragePhase loadTransactionStoragePhase(Slice slice) {
  final storageFeesCollected = slice.loadCoins();
  var storageFeesDue = slice.loadBool() == true ? slice.loadCoins() : null;
  final statusChange = loadAccountStatusChange(slice);

  return TransactionStoragePhase(
    storageFeesCollected: storageFeesCollected,
    storageFeesDue: storageFeesDue,
    statusChange: statusChange,
  );
}

void Function(Builder builder) storeTransactionStoragePhase(
    TransactionStoragePhase src) {
  return (Builder builder) {
    builder.storeCoins(src.storageFeesCollected);
    if (src.storageFeesDue == null) {
      builder.storeBit(0);
    } else {
      builder.storeBit(1);
      builder.storeCoins(src.storageFeesDue!);
    }
    builder.store(storeAccountStatusChange(src.statusChange));
  };
}
