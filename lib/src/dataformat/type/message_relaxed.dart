import '../cell/api.dart' show beginCell, Builder, Cell, Slice;
import 'api.dart'
    show
        CommonMessageInfoRelaxed,
        loadCommonMessageInfoRelaxed,
        storeCommonMessageInfoRelaxed,
        StateInit,
        loadStateInit,
        storeStateInit;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L151
// message$_ {X:Type} info:CommonMsgInfoRelaxed
//  init:(Maybe (Either StateInit ^StateInit))
//  body:(Either X ^X) = MessageRelaxed X;

/// ```dart
/// ({
///   CommonMessageInfoRelaxed info,
///   StateInit? init,
///   Cell body,
/// })
/// ```
class MessageRelaxed {
  final CommonMessageInfoRelaxed info;
  StateInit? init;
  final Cell body;

  MessageRelaxed({
    required this.info,
    this.init,
    required this.body,
  });
}

MessageRelaxed loadMessageRelaxed(Slice slice) {
  final info = loadCommonMessageInfoRelaxed(slice);
  StateInit? init;

  if (slice.loadBool()) {
    if (slice.loadBool() == false) {
      init = loadStateInit(slice);
    } else {
      init = loadStateInit(slice.loadRef().beginParse());
    }
  }

  final body = slice.loadBool() ? slice.loadRef() : slice.asCell();

  return MessageRelaxed(
    info: info,
    init: init,
    body: body,
  );
}

void Function(Builder builder) storeMessageRelaxed(
  MessageRelaxed message, {
  bool forceRef = false,
}) {
  return (Builder builder) {
    builder.store(storeCommonMessageInfoRelaxed(message.info));

    if (message.init == null) {
      builder.storeBit(0);
    } else {
      builder.storeBit(1);
      var initCell = beginCell().store(storeStateInit(message.init!));

      var needRef = false;
      if (forceRef) {
        needRef = true;
      } else if (builder.availableBits - 2 >= initCell.bits) {
        // very least for ref flag
        needRef = false;
      } else {
        needRef = true;
      }

      if (needRef) {
        builder.storeBit(1);
        builder.storeRef(initCell);
      } else {
        builder.storeBit(0);
        builder.storeBuilder(initCell);
      }
    }

    var needRef = false;
    if (forceRef) {
      needRef = true;
    } else {
      if (builder.availableBits - 1 >= message.body.bits.length &&
          builder.refs + message.body.refs.length <= 4) {
        // very least for ref flag
        needRef = false;
      } else {
        needRef = true;
      }
    }

    if (needRef) {
      builder.storeBit(1);
      builder.storeRef(message.body);
    } else {
      builder.storeBit(0);
      builder.storeBuilder(message.body.asBuilder());
    }
  };
}
