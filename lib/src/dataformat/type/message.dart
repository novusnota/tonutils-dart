import '../cell/api.dart' show beginCell, Builder, Cell, Slice;
import '../dictionary/api.dart' show DictionaryValue;
import 'api.dart'
    show
        CommonMessageInfo,
        loadCommonMessageInfo,
        storeCommonMessageInfo,
        StateInit,
        loadStateInit,
        storeStateInit;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L147
// message$_ {X:Type} info:CommonMsgInfo
//  init:(Maybe (Either StateInit ^StateInit))
//  body:(Either X ^X) = Message X;

/// ```dart
/// ({
///   CommonMessageInfo info,
///   StateInit? init,
///   Cell body,
/// })
/// ```
class Message {
  final CommonMessageInfo info;
  StateInit? init;
  final Cell body;

  Message({
    required this.info,
    this.init,
    required this.body,
  });
}

Message loadMessage(Slice slice) {
  final info = loadCommonMessageInfo(slice);
  StateInit? init;

  if (slice.loadBool()) {
    if (slice.loadBool() == false) {
      init = loadStateInit(slice);
    } else {
      init = loadStateInit(slice.loadRef().beginParse());
    }
  }

  final body = slice.loadBool() ? slice.loadRef() : slice.asCell();

  return Message(
    info: info,
    init: init,
    body: body,
  );
}

void Function(Builder builder) storeMessage(
  Message message, {
  bool forceRef = false,
}) {
  return (Builder builder) {
    builder.store(storeCommonMessageInfo(message.info));

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

final messageValue = DictionaryValue<Message>(
  serialize: (src, builder) {
    builder.storeRef(beginCell().store(storeMessage(src)));
  },
  parse: (slice) {
    return loadMessage(slice.loadRef().beginParse());
  },
);
