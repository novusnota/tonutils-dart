import '../../address/api.dart' show InternalAddress;
import '../../cell/api.dart' show Cell, beginCell;
import '../../nano/api.dart' show Nano;
import '../../contract/api.dart' show ContractMaybeInit;
import '../api.dart'
    show
        CmiExternalIn,
        CmirInternal,
        CurrencyCollection,
        Message,
        MessageRelaxed,
        SbiBigInt,
        SbiString,
        ScCell,
        ScString,
        SiaInternalAddress,
        SiaString,
        StateInit,
        StringBigInt,
        StringCell,
        StringInternalAddress;

MessageRelaxed internal({
  required StringInternalAddress to,
  required StringBigInt value,
  bool? bounce,
  ContractMaybeInit? init,
  StringCell? body,
}) {
  var iBounce = true;
  if (bounce != null) {
    iBounce = bounce;
  }

  var iTo = switch (to) {
    SiaString() => InternalAddress.parse(to.value),
    SiaInternalAddress() => to.value,
  };

  var iValue = switch (value) {
    SbiString() => Nano.fromString(value.value),
    SbiBigInt() => value.value,
  };

  var iBody = switch (body) {
    ScString() => beginCell()
        .storeUint(BigInt.zero, 32)
        .storeStringTail(body.value)
        .endCell(),
    ScCell() => body.value,
    null => Cell.empty,
  };

  return MessageRelaxed(
    info: CmirInternal(
      dest: iTo,
      value: CurrencyCollection(iValue),
      bounce: iBounce,
      ihrDisabled: true,
      bounced: false,
      ihrFee: BigInt.zero,
      forwardFee: BigInt.zero,
      createdLt: BigInt.zero,
      createdAt: 0,
    ),
    init: init == null ? null : StateInit(null, null, init.code, init.data),
    body: iBody,
  );
}

Message external({
  required StringInternalAddress to,
  ContractMaybeInit? init,
  Cell? body,
}) {
  var iTo = switch (to) {
    SiaString() => InternalAddress.parse(to.value),
    SiaInternalAddress() => to.value,
  };

  return Message(
    info: CmiExternalIn(dest: iTo, importFee: BigInt.zero),
    init: init == null ? null : StateInit(null, null, init.code, init.data),
    body: body ?? Cell.empty,
  );
}

Cell comment(String src) {
  return beginCell().storeUint(BigInt.zero, 32).storeStringTail(src).endCell();
}
