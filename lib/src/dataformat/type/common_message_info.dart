import '../address/api.dart' show InternalAddress, ExternalAddress;
import '../cell/api.dart' show Builder, Slice;
import 'api.dart'
    show CurrencyCollection, loadCurrencyCollection, storeCurrencyCollection;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L123
// int_msg_info$0 ihr_disabled:Bool bounce:Bool bounced:Bool
//  src:MsgAddressInt dest:MsgAddressInt
//  value:CurrencyCollection ihr_fee:Grams fwd_fee:Grams
//  created_lt:uint64 created_at:uint32 = CommonMsgInfo;
// ext_in_msg_info$10 src:MsgAddressExt dest:MsgAddressInt
//  import_fee:Grams = CommonMsgInfo;
// ext_out_msg_info$11 src:MsgAddressInt dest:MsgAddressExt
//  created_lt:uint64 created_at:uint32 = CommonMsgInfo;

/// Either of: CmiInternal, CmiExternalIn, CmiExternalOut
sealed class CommonMessageInfo {}

/// ```dart
/// ({
///   bool ihrDisabled,
///   bool bounce,
///   bool bounced,
///   InternalAddress src,
///   InternalAddress dest,
///   CurrencyCollection value,
///   BigInt ihrFee,
///   BigInt forwardFee,
///   BigInt createdLt,
///   int createdAt,
/// })
/// ```
class CmiInternal extends CommonMessageInfo {
  bool ihrDisabled;
  bool bounce;
  bool bounced;
  InternalAddress src;
  InternalAddress dest;
  CurrencyCollection value;
  BigInt ihrFee;
  BigInt forwardFee;
  BigInt createdLt;
  int createdAt;

  CmiInternal({
    required this.ihrDisabled,
    required this.bounce,
    required this.bounced,
    required this.src,
    required this.dest,
    required this.value,
    required this.ihrFee,
    required this.forwardFee,
    required this.createdLt,
    required this.createdAt,
  });
}

/// ```dart
/// ({
///   ExternalAddress? src,
///   InternalAddress dest,
///   BigInt importFee,
/// })
/// ```
class CmiExternalIn extends CommonMessageInfo {
  ExternalAddress? src;
  InternalAddress dest;
  BigInt importFee;

  CmiExternalIn({
    this.src,
    required this.dest,
    required this.importFee,
  });
}

/// ```dart
/// ({
///   InternalAddress src,
///   ExternalAddress? dest,
///   BigInt createdLt,
///   int createdAt,
/// })
/// ```
class CmiExternalOut extends CommonMessageInfo {
  InternalAddress src;
  ExternalAddress? dest;
  BigInt createdLt;
  int createdAt;

  CmiExternalOut({
    required this.src,
    this.dest,
    required this.createdLt,
    required this.createdAt,
  });
}

CommonMessageInfo loadCommonMessageInfo(Slice slice) {
  // Internal message
  if (slice.loadBit() == 0) {
    final ihrDisabled = slice.loadBit() == 0 ? false : true;
    final bounce = slice.loadBit() == 0 ? false : true;
    final bounced = slice.loadBit() == 0 ? false : true;

    final src = slice.loadInternalAddress();
    final dest = slice.loadInternalAddress();

    final value = loadCurrencyCollection(slice);

    final ihrFee = slice.loadCoins();
    final forwardFee = slice.loadCoins();

    final createdLt = slice.loadUintBig(64);
    final createdAt = slice.loadUint(32);

    return CmiInternal(
      ihrDisabled: ihrDisabled,
      bounce: bounce,
      bounced: bounced,
      src: src,
      dest: dest,
      value: value,
      ihrFee: ihrFee,
      forwardFee: forwardFee,
      createdLt: createdLt,
      createdAt: createdAt,
    );
  }

  // ExternalIn message
  if (slice.loadBit() == 0) {
    final src = slice.loadExternalAddressOrNull();
    final dest = slice.loadInternalAddress();
    final importFee = slice.loadCoins();

    return CmiExternalIn(
      src: src,
      dest: dest,
      importFee: importFee,
    );
  }

  // ExternalOut message
  final src = slice.loadInternalAddress();
  final dest = slice.loadExternalAddressOrNull();
  final createdLt = slice.loadUintBig(64);
  final createdAt = slice.loadUint(32);

  return CmiExternalOut(
    src: src,
    dest: dest,
    createdLt: createdLt,
    createdAt: createdAt,
  );
}

void Function(Builder builder) storeCommonMessageInfo(
    CommonMessageInfo source) {
  return (Builder builder) {
    switch (source) {
      case CmiInternal():
        builder.storeBit(0);
        builder.storeBit(source.ihrDisabled == true ? 1 : 0);
        builder.storeBit(source.bounce == true ? 1 : 0);
        builder.storeBit(source.bounced == true ? 1 : 0);
        builder.storeAddress(source.src);
        builder.storeAddress(source.dest);
        builder.store(storeCurrencyCollection(source.value));
        builder.storeCoins(source.ihrFee);
        builder.storeCoins(source.forwardFee);
        builder.storeUint(source.createdLt, 64);
        builder.storeUint(BigInt.from(source.createdAt), 32);

      case CmiExternalIn():
        builder.storeBit(1);
        builder.storeBit(0);
        builder.storeAddress(source.src);
        builder.storeAddress(source.dest);
        builder.storeCoins(source.importFee);

      case CmiExternalOut():
        builder.storeBit(1);
        builder.storeBit(1);
        builder.storeAddress(source.src);
        builder.storeAddress(source.dest);
        builder.storeUint(source.createdLt, 64);
        builder.storeUint(BigInt.from(source.createdAt), 32);
    }
  };
}
