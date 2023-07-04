import '../cell/api.dart' show Builder, Slice;
import 'api.dart'
    show CurrencyCollection, loadCurrencyCollection, storeCurrencyCollection;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L293
// tr_phase_credit$_ due_fees_collected:(Maybe Grams)
//   credit:CurrencyCollection = TrCreditPhase;

/// ```dart
/// ({
///   BigInt? dueFeesCollected,
///   CurrencyCollection credit,
/// })
/// ```
class TransactionCreditPhase {
  final BigInt? dueFeesCollected;
  final CurrencyCollection credit;

  TransactionCreditPhase({
    this.dueFeesCollected,
    required this.credit,
  });
}

loadTransactionCreditPhase(Slice slice) {
  final dueFeesCollected = slice.loadBool() == true ? slice.loadCoins() : null;
  final credit = loadCurrencyCollection(slice);

  return TransactionCreditPhase(
    dueFeesCollected: dueFeesCollected,
    credit: credit,
  );
}

void Function(Builder builder) storeTransactionCreditPhase(
    TransactionCreditPhase src) {
  return (Builder builder) {
    if (src.dueFeesCollected == null) {
      builder.storeBit(0);
    } else {
      builder.storeBit(1);
      builder.storeCoins(src.dueFeesCollected!);
    }
    builder.store(storeCurrencyCollection(src.credit));
  };
}
