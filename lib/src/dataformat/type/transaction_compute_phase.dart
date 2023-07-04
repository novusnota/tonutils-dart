import '../cell/api.dart' show beginCell, Builder, Slice;
import 'api.dart'
    show ComputeSkipReason, loadComputeSkipReason, storeComputeSkipReason;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L296
// tr_phase_compute_skipped$0 reason:ComputeSkipReason
//   = TrComputePhase;
// tr_phase_compute_vm$1 success:Bool msg_state_used:Bool
//   account_activated:Bool gas_fees:Grams
//   ^[ gas_used:(VarUInteger 7)
//      gas_limit:(VarUInteger 7) gas_credit:(Maybe (VarUInteger 3))
//      mode:int8 exit_code:int32 exit_arg:(Maybe int32)
//      vm_steps:uint32
//      vm_init_state_hash:bits256 vm_final_state_hash:bits256 ]
//   = TrComputePhase;

/// Either of: TcpSkipped, TcpVm
sealed class TransactionComputePhase {}

/// ({ ComputeSkipReason reason })
class TcpSkipped extends TransactionComputePhase {
  ComputeSkipReason reason;

  TcpSkipped({
    required this.reason,
  });
}

/// ```dart
/// ({
///   bool success,
///   bool messageStateUsed,
///   bool accountActivated,
///   BigInt gasFees,
///   BigInt gasUsed,
///   BigInt gasLimit,
///   BigInt? gasCredit,
///   int mode,
///   int exitCode,
///   int? exitArg,
///   int vmSteps,
///   BigInt vmInitStateHash,
///   BigInt vmFinalStateHash,
/// })
/// ```
class TcpVm extends TransactionComputePhase {
  bool success;
  bool messageStateUsed;
  bool accountActivated;
  BigInt gasFees;
  BigInt gasUsed;
  BigInt gasLimit;
  BigInt? gasCredit;
  int mode;
  int exitCode;
  int? exitArg;
  int vmSteps;
  BigInt vmInitStateHash;
  BigInt vmFinalStateHash;

  TcpVm({
    required this.success,
    required this.messageStateUsed,
    required this.accountActivated,
    required this.gasFees,
    required this.gasUsed,
    required this.gasLimit,
    this.gasCredit,
    required this.mode,
    required this.exitCode,
    this.exitArg,
    required this.vmSteps,
    required this.vmInitStateHash,
    required this.vmFinalStateHash,
  });
}

TransactionComputePhase loadTransactionComputePhase(Slice slice) {
  // Skipped
  if (slice.loadBool() == false) {
    var reason = loadComputeSkipReason(slice);

    return TcpSkipped(reason: reason);
  }

  var success = slice.loadBool();
  var messageStateUsed = slice.loadBool();
  var accountActivated = slice.loadBool();
  var gasFees = slice.loadCoins();

  final vmState = slice.loadRef().beginParse();
  var gasUsed = vmState.loadVarUintBig(3);
  var gasLimit = vmState.loadVarUintBig(3);
  var gasCredit = vmState.loadBool() == true ? vmState.loadVarUintBig(2) : null;

  var mode = vmState.loadUint(8);
  var exitCode = vmState.loadUint(32);
  var exitArg = vmState.loadBool() == true ? vmState.loadInt(32) : null;

  var vmSteps = vmState.loadUint(32);
  var vmInitStateHash = vmState.loadUintBig(256);
  var vmFinalStateHash = vmState.loadUintBig(256);

  return TcpVm(
    success: success,
    messageStateUsed: messageStateUsed,
    accountActivated: accountActivated,
    gasFees: gasFees,
    gasUsed: gasUsed,
    gasLimit: gasLimit,
    gasCredit: gasCredit,
    mode: mode,
    exitCode: exitCode,
    exitArg: exitArg,
    vmSteps: vmSteps,
    vmInitStateHash: vmInitStateHash,
    vmFinalStateHash: vmFinalStateHash,
  );
}

void Function(Builder builder) storeTransactionComputePhase(
    TransactionComputePhase src) {
  return (Builder builder) {
    switch (src) {
      case TcpSkipped():
        builder.storeBit(0);
        builder.store(storeComputeSkipReason(src.reason));

      case TcpVm():
        builder.storeBit(1);
        builder.storeBool(src.success);
        builder.storeBool(src.messageStateUsed);
        builder.storeBool(src.accountActivated);
        builder.storeCoins(src.gasFees);
        builder.storeRef(beginCell()
            .storeVarUint(src.gasUsed, 3)
            .storeVarUint(src.gasLimit, 3)
            .store((Builder b) {
              return src.gasCredit != null
                  ? b.storeBit(1).storeVarUint(src.gasCredit!, 2)
                  : b.storeBit(0);
            })
            .storeUint(BigInt.from(src.mode), 8)
            .storeUint(BigInt.from(src.exitCode), 32)
            .store((Builder b) {
              return src.exitArg != null
                  ? b.storeBit(1).storeInt(BigInt.from(src.exitArg!), 32)
                  : b.storeBit(0);
            })
            .storeUint(BigInt.from(src.vmSteps), 32)
            .storeUint(src.vmInitStateHash, 256)
            .storeUint(src.vmFinalStateHash, 256)
            .endCell());
    }
  };
}
