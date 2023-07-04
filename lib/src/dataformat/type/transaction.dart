import '../cell/api.dart' show beginCell, Builder, Slice;
import '../dictionary/api.dart' show Dictionary, DktInt;
import 'api.dart'
    show
        AccountStatus,
        loadAccountStatus,
        storeAccountStatus,
        CurrencyCollection,
        loadCurrencyCollection,
        storeCurrencyCollection,
        HashUpdate,
        loadHashUpdate,
        storeHashUpdate,
        Message,
        messageValue,
        loadMessage,
        storeMessage,
        TransactionDescription,
        loadTransactionDescription,
        storeTransactionDescription;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L263
// transaction$0111 account_addr:bits256 lt:uint64
//  prev_trans_hash:bits256 prev_trans_lt:uint64 now:uint32
//  outmsg_cnt:uint15
//  orig_status:AccountStatus end_status:AccountStatus
//  ^[ in_msg:(Maybe ^(Message Any)) out_msgs:(HashmapE 15 ^(Message Any)) ]
//  total_fees:CurrencyCollection state_update:^(HASH_UPDATE Account)
//  description:^TransactionDescr = Transaction;

/// ```dart
/// ({
///   BigInt address,
///   BigInt lt,
///   BigInt prevTransactionHash,
///   BigInt prevTransactionLt,
///   int now,
///   int outMessagesCount,
///   AccountStatus oldStatus,
///   AccountStatus endStatus,
///   Message? inMessage,
///   Dictionary<DktInt, Message> outMessages,
///   CurrencyCollection totalFees,
///   HashUpdate stateUpdate,
///   TransactionDescription description,
/// })
/// ```
class Transaction {
  BigInt address;
  BigInt lt;
  BigInt prevTransactionHash;
  BigInt prevTransactionLt;
  int now;
  int outMessagesCount;
  AccountStatus oldStatus;
  AccountStatus endStatus;
  Message? inMessage;
  Dictionary<DktInt, Message> outMessages;
  CurrencyCollection totalFees;
  HashUpdate stateUpdate;
  TransactionDescription description;

  Transaction({
    required this.address,
    required this.lt,
    required this.prevTransactionHash,
    required this.prevTransactionLt,
    required this.now,
    required this.outMessagesCount,
    required this.oldStatus,
    required this.endStatus,
    this.inMessage,
    required this.outMessages,
    required this.totalFees,
    required this.stateUpdate,
    required this.description,
  });
}

/// Throws 'Invalid data' if read uint of 4 bits != 0x07
Transaction loadTransaction(Slice slice) {
  if (slice.loadUint(4) != 0x07) {
    throw 'Invalid data';
  }

  var address = slice.loadUintBig(256);
  var lt = slice.loadUintBig(64);
  var prevTransactionHash = slice.loadUintBig(256);
  var prevTransactionLt = slice.loadUintBig(64);

  var now = slice.loadUint(32);
  var outMessagesCount = slice.loadUint(15);

  // check
  var oldStatus = loadAccountStatus(slice);
  var endStatus = loadAccountStatus(slice);

  var msgRef = slice.loadRef();
  var msgSlice = msgRef.beginParse();
  var inMessage = msgSlice.loadBool() == true
      ? loadMessage(msgSlice.loadRef().beginParse())
      : null;
  var outMessages =
      msgSlice.loadDictionary(Dictionary.createKeyUint(15), messageValue);
  msgSlice.endParse();

  var totalFees = loadCurrencyCollection(slice);
  var stateUpdate = loadHashUpdate(slice.loadRef().beginParse());
  var description = loadTransactionDescription(slice.loadRef().beginParse());

  return Transaction(
    address: address,
    lt: lt,
    prevTransactionHash: prevTransactionHash,
    prevTransactionLt: prevTransactionLt,
    now: now,
    outMessagesCount: outMessagesCount,
    oldStatus: oldStatus,
    endStatus: endStatus,
    inMessage: inMessage,
    outMessages: outMessages,
    totalFees: totalFees,
    stateUpdate: stateUpdate,
    description: description,
  );
}

void Function(Builder builder) storeTransaction(Transaction src) {
  return (Builder builder) {
    builder.storeUint(BigInt.from(0x07), 4);
    builder.storeUint(src.address, 256);
    builder.storeUint(src.lt, 64);
    builder.storeUint(src.prevTransactionHash, 256);
    builder.storeUint(src.prevTransactionLt, 64);
    builder.storeUint(BigInt.from(src.now), 32);
    builder.storeUint(BigInt.from(src.outMessagesCount), 15);
    builder.store(storeAccountStatus(src.oldStatus));
    builder.store(storeAccountStatus(src.endStatus));

    var msgBuilder = beginCell();
    if (src.inMessage != null) {
      msgBuilder.storeBit(1);
      msgBuilder.storeRef(beginCell().store(storeMessage(src.inMessage!)));
    } else {
      msgBuilder.storeBit(0);
    }
    msgBuilder.storeDictionary(src.outMessages);
    builder.storeRef(msgBuilder);

    builder.store(storeCurrencyCollection(src.totalFees));
    builder.storeRef(beginCell().store(storeHashUpdate(src.stateUpdate)));
    builder.storeRef(
        beginCell().store(storeTransactionDescription(src.description)));
  };
}
