import '../address/api.dart' show InternalAddress, ExternalAddress;
import '../cell/api.dart' show Builder, Slice;
import 'api.dart'
    show CurrencyCollection, loadCurrencyCollection, storeCurrencyCollection;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L132
// int_msg_info$0 ihr_disabled:Bool bounce:Bool bounced:Bool
//   src:MsgAddress dest:MsgAddressInt
//   value:CurrencyCollection ihr_fee:Grams fwd_fee:Grams
//   created_lt:uint64 created_at:uint32 = CommonMsgInfoRelaxed;
// ext_out_msg_info$11 src:MsgAddress dest:MsgAddressExt
//   created_lt:uint64 created_at:uint32 = CommonMsgInfoRelaxed;

/// Either of: CmirInternal, CmirExternalOut
sealed class CommonMessageInfoRelaxed {}

/// ```dart
/// ({
///   bool ihrDisabled,
///   bool bounce,
///   bool bounced,
///   InternalAddress? src,
///   InternalAddress dest,
///   CurrencyCollection value,
///   BigInt ihrFee,
///   BigInt forwardFee,
///   BigInt createdLt,
///   int createdAt,
/// })
/// ```
class CmirInternal extends CommonMessageInfoRelaxed {
  bool ihrDisabled;
  bool bounce;
  bool bounced;
  InternalAddress? src;
  InternalAddress dest;
  CurrencyCollection value;
  BigInt ihrFee;
  BigInt forwardFee;
  BigInt createdLt;
  int createdAt;

  CmirInternal({
    required this.ihrDisabled,
    required this.bounce,
    required this.bounced,
    this.src,
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
///   InternalAddress? src,
///   ExternalAddress? dest,
///   BigInt createdLt,
///   int createdAt,
/// })
/// ```
///
/// Throws 'ExternalIn message is not possible for the CommonMessageInfoRelaxed' if the second loaded bit would also be equal to zero
class CmirExternalOut extends CommonMessageInfoRelaxed {
  InternalAddress? src;
  ExternalAddress? dest;
  BigInt createdLt;
  int createdAt;

  CmirExternalOut({
    this.src,
    this.dest,
    required this.createdLt,
    required this.createdAt,
  });
}

CommonMessageInfoRelaxed loadCommonMessageInfoRelaxed(Slice slice) {
  // Internal message
  if (slice.loadBit() == 0) {
    final ihrDisabled = slice.loadBit() == 0 ? false : true;
    final bounce = slice.loadBit() == 0 ? false : true;
    final bounced = slice.loadBit() == 0 ? false : true;

    final src = slice.loadInternalAddressOrNull();
    final dest = slice.loadInternalAddress();

    final value = loadCurrencyCollection(slice);

    final ihrFee = slice.loadCoins();
    final forwardFee = slice.loadCoins();

    final createdLt = slice.loadUintBig(64);
    final createdAt = slice.loadUint(32);

    return CmirInternal(
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
    throw 'ExternalIn message is not possible for the CommonMessageInfoRelaxed';
  }

  // ExternalOut message
  final src = slice.loadInternalAddressOrNull();
  final dest = slice.loadExternalAddressOrNull();
  final createdLt = slice.loadUintBig(64);
  final createdAt = slice.loadUint(32);

  return CmirExternalOut(
    src: src,
    dest: dest,
    createdLt: createdLt,
    createdAt: createdAt,
  );
}

void Function(Builder builder) storeCommonMessageInfoRelaxed(
    CommonMessageInfoRelaxed source) {
  return (Builder builder) {
    switch (source) {
      case CmirInternal():
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

      case CmirExternalOut():
        builder.storeBit(1);
        builder.storeBit(1);
        builder.storeAddress(source.src);
        builder.storeAddress(source.dest);
        builder.storeUint(source.createdLt, 64);
        builder.storeUint(BigInt.from(source.createdAt), 32);
    }
  };
}
