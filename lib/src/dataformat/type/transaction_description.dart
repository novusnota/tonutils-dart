import '../cell/api.dart' show beginCell, Builder, Slice;
import 'api.dart'
    show
        SplitMergeInfo,
        Transaction,
        TransactionActionPhase,
        TransactionBouncePhase,
        TransactionComputePhase,
        TransactionCreditPhase,
        TransactionStoragePhase,
        loadSplitMergeInfo,
        loadTransaction,
        loadTransactionActionPhase,
        loadTransactionBouncePhase,
        loadTransactionComputePhase,
        loadTransactionCreditPhase,
        loadTransactionStoragePhase,
        storeSplitMergeInfo,
        storeTransaction,
        storeTransactionActionPhase,
        storeTransactionBouncePhase,
        storeTransactionComputePhase,
        storeTransactionCreditPhase,
        storeTransactionStoragePhase;

// Transaction, loadTransaction, storeTransaction

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L324
// trans_ord$0000 credit_first:Bool
//   storage_ph:(Maybe TrStoragePhase)
//   credit_ph:(Maybe TrCreditPhase)
//   compute_ph:TrComputePhase action:(Maybe ^TrActionPhase)
//   aborted:Bool bounce:(Maybe TrBouncePhase)
//   destroyed:Bool
//   = TransactionDescr;

// trans_storage$0001 storage_ph:TrStoragePhase
//   = TransactionDescr;

// trans_tick_tock$001 is_tock:Bool storage_ph:TrStoragePhase
//   compute_ph:TrComputePhase action:(Maybe ^TrActionPhase)
//   aborted:Bool destroyed:Bool = TransactionDescr;

// trans_split_prepare$0100 split_info:SplitMergeInfo
//   storage_ph:(Maybe TrStoragePhase)
//   compute_ph:TrComputePhase action:(Maybe ^TrActionPhase)
//   aborted:Bool destroyed:Bool
//   = TransactionDescr;

// trans_split_install$0101 split_info:SplitMergeInfo
//   prepare_transaction:^Transaction
//   installed:Bool = TransactionDescr;

// trans_merge_prepare$0110 split_info:SplitMergeInfo
//   storage_ph:TrStoragePhase aborted:Bool
//   = TransactionDescr;

// trans_merge_install$0111 split_info:SplitMergeInfo
//   prepare_transaction:^Transaction
//   storage_ph:(Maybe TrStoragePhase)
//   credit_ph:(Maybe TrCreditPhase)
//   compute_ph:TrComputePhase action:(Maybe ^TrActionPhase)
//   aborted:Bool destroyed:Bool
//   = TransactionDescr;

/// Either of: TdGeneric, TdStorage, TdTickTock, TdSplitPrepare, TdSplitInstall, TdMergePrepare, TdMergeInstall
sealed class TransactionDescription {
  /// 0x00
  static const int generic = 0x00;

  /// 0x01
  static const int storage = 0x01;

  /// 0x02
  static const int tick = 0x02;

  /// 0x03
  static const int tock = 0x03;

  /// 0x04
  static const int splitPrepare = 0x04;

  /// 0x05
  static const int splitInstall = 0x05;
  // NOTE: 6, 7 for merge prep/install?
}

/// ```dart
/// ({
///   bool creditFirst,
///   TransactionStoragePhase? storagePhase,
///   TransactionCreditPhase? creditPhase,
///   TransactionComputePhase computePhase,
///   TransactionActionPhase? actionPhase,
///   bool aborted,
///   TransactionBouncePhase? bouncePhase,
///   bool destroyed,
/// })
/// ```
class TdGeneric extends TransactionDescription {
  final bool creditFirst;
  TransactionStoragePhase? storagePhase;
  TransactionCreditPhase? creditPhase;
  TransactionComputePhase computePhase;
  TransactionActionPhase? actionPhase;
  bool aborted;
  TransactionBouncePhase? bouncePhase;
  final bool destroyed;

  TdGeneric({
    required this.creditFirst,
    this.storagePhase,
    this.creditPhase,
    required this.computePhase,
    this.actionPhase,
    required this.aborted,
    this.bouncePhase,
    required this.destroyed,
  });
}

/// ```dart
/// ({
///   TransactionStoragePhase storagePhase,
/// })
/// ```
class TdStorage extends TransactionDescription {
  TransactionStoragePhase storagePhase;

  TdStorage({
    required this.storagePhase,
  });
}

/// ```dart
/// ({
///   bool isTock,
///   TransactionStoragePhase storagePhase,
///   TransactionComputePhase computePhase,
///   TransactionActionPhase? actionPhase,
///   bool aborted,
///   bool destroyed,
/// })
/// ```
class TdTickTock extends TransactionDescription {
  final bool isTock;
  TransactionStoragePhase storagePhase;
  TransactionComputePhase computePhase;
  TransactionActionPhase? actionPhase;
  final bool aborted;
  final bool destroyed;

  TdTickTock({
    required this.isTock,
    required this.storagePhase,
    required this.computePhase,
    this.actionPhase,
    required this.aborted,
    required this.destroyed,
  });
}

/// ```dart
/// ({
///   SplitMergeInfo splitInfo,
///   TransactionStoragePhase? storagePhase,
///   TransactionComputePhase computePhase,
///   TransactionActionPhase? actionPhase,
///   bool aborted,
///   bool destroyed,
/// })
/// ```
class TdSplitPrepare extends TransactionDescription {
  SplitMergeInfo splitInfo;
  TransactionStoragePhase? storagePhase;
  TransactionComputePhase computePhase;
  TransactionActionPhase? actionPhase;
  final bool aborted;
  final bool destroyed;

  TdSplitPrepare({
    required this.splitInfo,
    this.storagePhase,
    required this.computePhase,
    this.actionPhase,
    required this.aborted,
    required this.destroyed,
  });
}

/// ```dart
/// ({
///   SplitMergeInfo splitInfo,
///   Transaction prepareTransaction,
///   bool installed,
/// })
/// ```
class TdSplitInstall extends TransactionDescription {
  SplitMergeInfo splitInfo;
  Transaction prepareTransaction;
  final bool installed;

  TdSplitInstall({
    required this.splitInfo,
    required this.prepareTransaction,
    required this.installed,
  });
}

/// ```dart
/// ({
///   SplitMergeInfo splitInfo,
///   TransactionStoragePhase storagePhase,
///   bool aborted,
/// })
/// ```
class TdMergePrepare extends TransactionDescription {
  SplitMergeInfo splitInfo;
  TransactionStoragePhase storagePhase;
  bool aborted;

  TdMergePrepare({
    required this.splitInfo,
    required this.storagePhase,
    required this.aborted,
  });
}

/// ```dart
/// ({
///   SplitMergeInfo splitInfo,
///   Transaction prepareTransaction,
///   TransactionStoragePhase? storagePhase,
///   TransactionCreditPhase? creditPhase,
///   TransactionComputePhase computePhase,
///   TransactionActionPhase? actionPhase,
///   bool aborted,
///   bool destroyed,
/// })
/// ```
class TdMergeInstall extends TransactionDescription {
  SplitMergeInfo splitInfo;
  Transaction prepareTransaction;
  TransactionStoragePhase? storagePhase;
  TransactionCreditPhase? creditPhase;
  TransactionComputePhase computePhase;
  TransactionActionPhase? actionPhase;
  bool aborted;
  bool destroyed;

  TdMergeInstall({
    required this.splitInfo,
    required this.prepareTransaction,
    this.storagePhase,
    this.creditPhase,
    required this.computePhase,
    this.actionPhase,
    required this.aborted,
    required this.destroyed,
  });
}

/// Throws 'Unsupported transaction...' on unsupported transaction description type
TransactionDescription loadTransactionDescription(Slice slice) {
  var type = slice.loadUint(4);
  switch (type) {
    case TransactionDescription.generic:
      final creditFirst = slice.loadBool();
      var storagePhase =
          slice.loadBool() == true ? loadTransactionStoragePhase(slice) : null;

      var creditPhase =
          slice.loadBool() == true ? loadTransactionCreditPhase(slice) : null;

      var computePhase = loadTransactionComputePhase(slice);

      var actionPhase = slice.loadBool() == true
          ? loadTransactionActionPhase(slice.loadRef().beginParse())
          : null;

      var aborted = slice.loadBool();

      var bouncePhase =
          slice.loadBool() == true ? loadTransactionBouncePhase(slice) : null;

      final destroyed = slice.loadBool();

      return TdGeneric(
        creditFirst: creditFirst,
        storagePhase: storagePhase,
        creditPhase: creditPhase,
        computePhase: computePhase,
        actionPhase: actionPhase,
        aborted: aborted,
        bouncePhase: bouncePhase,
        destroyed: destroyed,
      );

    case TransactionDescription.storage:
      var storagePhase = loadTransactionStoragePhase(slice);

      return TdStorage(
        storagePhase: storagePhase,
      );

    case TransactionDescription.tick:
    case TransactionDescription.tock:
      final isTock = type == TransactionDescription.tock;
      var storagePhase = loadTransactionStoragePhase(slice);
      var computePhase = loadTransactionComputePhase(slice);
      var actionPhase = slice.loadBool() == true
          ? loadTransactionActionPhase(slice.loadRef().beginParse())
          : null;
      final aborted = slice.loadBool();
      final destroyed = slice.loadBool();

      return TdTickTock(
        isTock: isTock,
        storagePhase: storagePhase,
        computePhase: computePhase,
        actionPhase: actionPhase,
        aborted: aborted,
        destroyed: destroyed,
      );

    case TransactionDescription.splitPrepare:
      var splitInfo = loadSplitMergeInfo(slice);
      var storagePhase =
          slice.loadBool() ? loadTransactionStoragePhase(slice) : null;
      var computePhase = loadTransactionComputePhase(slice);
      var actionPhase = slice.loadBool()
          ? loadTransactionActionPhase(slice.loadRef().beginParse())
          : null;
      final aborted = slice.loadBool();
      final destroyed = slice.loadBool();

      return TdSplitPrepare(
        splitInfo: splitInfo,
        storagePhase: storagePhase,
        computePhase: computePhase,
        actionPhase: actionPhase,
        aborted: aborted,
        destroyed: destroyed,
      );

    case TransactionDescription.splitInstall:
      var splitInfo = loadSplitMergeInfo(slice);
      var prepareTransaction = loadTransaction(slice.loadRef().beginParse());
      final installed = slice.loadBool();

      return TdSplitInstall(
        splitInfo: splitInfo,
        prepareTransaction: prepareTransaction,
        installed: installed,
      );

    case _:
      throw 'Unsupported transaction description type $type';
  }
}

void Function(Builder builder) storeTransactionDescription(
    TransactionDescription src) {
  return (Builder builder) {
    switch (src) {
      case TdGeneric():
        builder.storeUint(BigInt.from(TransactionDescription.generic), 4);

        builder.storeBool(src.creditFirst);

        if (src.storagePhase != null) {
          builder.storeBit(1);
          builder.store(storeTransactionStoragePhase(src.storagePhase!));
        } else {
          builder.storeBit(0);
        }

        if (src.creditPhase != null) {
          builder.storeBit(1);
          builder.store(storeTransactionCreditPhase(src.creditPhase!));
        } else {
          builder.storeBit(0);
        }

        builder.store(storeTransactionComputePhase(src.computePhase));

        if (src.actionPhase != null) {
          builder.storeBit(1);
          builder.storeRef(
              beginCell().store(storeTransactionActionPhase(src.actionPhase!)));
        } else {
          builder.storeBit(0);
        }

        builder.storeBool(src.aborted);

        if (src.bouncePhase != null) {
          builder.storeBit(1);
          builder.store(storeTransactionBouncePhase(src.bouncePhase!));
        } else {
          builder.storeBit(0);
        }

        builder.storeBool(src.destroyed);

      case TdStorage():
        builder.storeUint(BigInt.from(TransactionDescription.storage), 4);
        builder.store(storeTransactionStoragePhase(src.storagePhase));

      case TdTickTock():
        builder.storeUint(
            BigInt.from(src.isTock
                ? TransactionDescription.tock
                : TransactionDescription.tick),
            4);

        builder.store(storeTransactionStoragePhase(src.storagePhase));

        builder.store(storeTransactionComputePhase(src.computePhase));

        if (src.actionPhase != null) {
          builder.storeBit(1);
          builder.storeRef(
              beginCell().store(storeTransactionActionPhase(src.actionPhase!)));
        } else {
          builder.storeBit(0);
        }

        builder.storeBool(src.aborted);

        builder.storeBool(src.destroyed);

      case TdSplitPrepare():
        builder.storeUint(BigInt.from(TransactionDescription.splitPrepare), 4);

        builder.store(storeSplitMergeInfo(src.splitInfo));

        if (src.storagePhase != null) {
          builder.storeBit(1);
          builder.store(storeTransactionStoragePhase(src.storagePhase!));
        } else {
          builder.storeBit(0);
        }

        builder.store(storeTransactionComputePhase(src.computePhase));

        if (src.actionPhase != null) {
          builder.storeBit(1);
          builder.store(storeTransactionActionPhase(src.actionPhase!));
        } else {
          builder.storeBit(0);
        }

        builder.storeBool(src.aborted);

        builder.storeBool(src.destroyed);

      case TdSplitInstall():
        builder.storeUint(BigInt.from(TransactionDescription.splitInstall), 4);

        builder.store(storeSplitMergeInfo(src.splitInfo));

        builder.storeRef(
            beginCell().store(storeTransaction(src.prepareTransaction)));

        builder.storeBool(src.installed);

      case TdMergePrepare():
        throw 'Unsupported transaction description type $src';

      case TdMergeInstall():
        throw 'Unsupported transaction description type $src';
    }
  };
}
