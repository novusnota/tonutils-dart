import '../cell/api.dart' show Builder, Slice;
import 'api.dart'
    show StorageUsedShort, loadStorageUsedShort, storeStorageUsedShort;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L318
// tr_phase_bounce_negfunds$00 = TrBouncePhase;
// tr_phase_bounce_nofunds$01 msg_size:StorageUsedShort req_fwd_fees:Grams = TrBouncePhase;
// tr_phase_bounce_ok$1 msg_size:StorageUsedShort msg_fees:Grams fwd_fees:Grams = TrBouncePhase;

/// Either of: TbpNegativeFunds, TbpNoFunds, TbpOk
sealed class TransactionBouncePhase {}

/// Empty class, used as a type name
class TbpNegativeFunds extends TransactionBouncePhase {}

/// ```dart
/// ({
///   StorageUsedShort messageSize,
///   BigInt requiredForwardFees,
/// })
///```
class TbpNoFunds extends TransactionBouncePhase {
  StorageUsedShort messageSize;
  BigInt requiredForwardFees;

  TbpNoFunds({
    required this.messageSize,
    required this.requiredForwardFees,
  });
}

/// ```dart
/// ({
///   StorageUsedShort messageSize,
///   BigInt messageFees,
///   BigInt forwardFees,
/// })
/// ```
class TbpOk extends TransactionBouncePhase {
  StorageUsedShort messageSize;
  BigInt messageFees;
  BigInt forwardFees;

  TbpOk({
    required this.messageSize,
    required this.messageFees,
    required this.forwardFees,
  });
}

TransactionBouncePhase loadTransactionBouncePhase(Slice slice) {
  // Ok
  if (slice.loadBool()) {
    var messageSize = loadStorageUsedShort(slice);
    var messageFees = slice.loadCoins();
    var forwardFees = slice.loadCoins();

    return TbpOk(
      messageSize: messageSize,
      messageFees: messageFees,
      forwardFees: forwardFees,
    );
  }

  // No funds
  if (slice.loadBool()) {
    var messageSize = loadStorageUsedShort(slice);
    var requiredForwardFees = slice.loadCoins();

    return TbpNoFunds(
      messageSize: messageSize,
      requiredForwardFees: requiredForwardFees,
    );
  }

  // Negative funds
  return TbpNegativeFunds();
}

void Function(Builder builder) storeTransactionBouncePhase(
    TransactionBouncePhase src) {
  return (Builder builder) {
    switch (src) {
      case TbpOk():
        builder.storeBit(1);
        builder.store(storeStorageUsedShort(src.messageSize));
        builder.storeCoins(src.messageFees);
        builder.storeCoins(src.forwardFees);

      case TbpNoFunds():
        builder.storeBit(0);
        builder.storeBit(1);
        builder.store(storeStorageUsedShort(src.messageSize));
        builder.storeCoins(src.requiredForwardFees);

      case TbpNegativeFunds():
        builder.storeBit(0);
        builder.storeBit(0);
    }
  };
}
