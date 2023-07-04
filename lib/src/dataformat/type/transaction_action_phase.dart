import '../cell/api.dart' show Builder, Slice;
import 'api.dart'
    show
        AccountStatusChange,
        loadAccountStatusChange,
        storeAccountStatusChange,
        StorageUsedShort,
        loadStorageUsedShort,
        storeStorageUsedShort;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L310
// tr_phase_action$_ success:Bool valid:Bool no_funds:Bool
//   status_change:AccStatusChange
//   total_fwd_fees:(Maybe Grams) total_action_fees:(Maybe Grams)
//   result_code:int32 result_arg:(Maybe int32) tot_actions:uint16
//   spec_actions:uint16 skipped_actions:uint16 msgs_created:uint16
//   action_list_hash:bits256 tot_msg_size:StorageUsedShort
//   = TrActionPhase;

/// ```dart
/// ({
///   bool success,
///   bool valid,
///   bool noFunds,
///   AccountStatusChange statusChange,
///   BigInt? totalForwardFees,
///   BigInt? totalActionFees,
///   int resultCode,
///   int? resultArg,
///   int totalActions,
///   int specActions,
///   int skippedActions,
///   int messagesCreated,
///   BigInt actionListHash,
///   StorageUsedShort totalMessageSize,
/// })
/// ```
class TransactionActionPhase {
  bool success;
  bool valid;
  bool noFunds;
  AccountStatusChange statusChange;
  BigInt? totalForwardFees;
  BigInt? totalActionFees;
  int resultCode;
  int? resultArg;
  int totalActions;
  int specActions;
  int skippedActions;
  int messagesCreated;
  BigInt actionListHash;
  StorageUsedShort totalMessageSize;

  TransactionActionPhase({
    required this.success,
    required this.valid,
    required this.noFunds,
    required this.statusChange,
    this.totalForwardFees,
    this.totalActionFees,
    required this.resultCode,
    this.resultArg,
    required this.totalActions,
    required this.specActions,
    required this.skippedActions,
    required this.messagesCreated,
    required this.actionListHash,
    required this.totalMessageSize,
  });
}

TransactionActionPhase loadTransactionActionPhase(Slice slice) {
  var success = slice.loadBool();
  var valid = slice.loadBool();
  var noFunds = slice.loadBool();
  var statusChange = loadAccountStatusChange(slice);
  var totalForwardFees = slice.loadBool() ? slice.loadCoins() : null;
  var totalActionFees = slice.loadBool() ? slice.loadCoins() : null;
  var resultCode = slice.loadInt(32);
  var resultArg = slice.loadBool() ? slice.loadInt(32) : null;
  var totalActions = slice.loadUint(16);
  var specActions = slice.loadUint(16);
  var skippedActions = slice.loadUint(16);
  var messagesCreated = slice.loadUint(16);
  var actionListHash = slice.loadUintBig(256);
  var totalMessageSize = loadStorageUsedShort(slice);

  return TransactionActionPhase(
    success: success,
    valid: valid,
    noFunds: noFunds,
    statusChange: statusChange,
    totalForwardFees: totalForwardFees,
    totalActionFees: totalActionFees,
    resultCode: resultCode,
    resultArg: resultArg,
    totalActions: totalActions,
    specActions: specActions,
    skippedActions: skippedActions,
    messagesCreated: messagesCreated,
    actionListHash: actionListHash,
    totalMessageSize: totalMessageSize,
  );
}

void Function(Builder builder) storeTransactionActionPhase(
    TransactionActionPhase src) {
  return (Builder builder) {
    builder.storeBool(src.success);
    builder.storeBool(src.valid);
    builder.storeBool(src.noFunds);
    builder.store(storeAccountStatusChange(src.statusChange));
    builder.storeMaybeCoins(src.totalForwardFees);
    builder.storeMaybeCoins(src.totalActionFees);
    builder.storeInt(BigInt.from(src.resultCode), 32);
    if (src.resultArg == null) {
      builder.storeMaybeInt(null, 32);
    } else {
      builder.storeMaybeInt(BigInt.from(src.resultArg!), 32);
    }
    builder.storeUint(BigInt.from(src.totalActions), 16);
    builder.storeUint(BigInt.from(src.specActions), 16);
    builder.storeUint(BigInt.from(src.skippedActions), 16);
    builder.storeUint(BigInt.from(src.messagesCreated), 16);
    builder.storeUint(src.actionListHash, 256);
    builder.store(storeStorageUsedShort(src.totalMessageSize));
  };
}
