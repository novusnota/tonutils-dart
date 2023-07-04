import 'dart:typed_data';

import '../../dataformat/type/api.dart'
    show MessageRelaxed, storeMessageRelaxed;
import '../../dataformat/cell/api.dart' show Cell, beginCell;
import '../../crypto/nacl/api.dart' show sign;

/// Throws 'Expected <= 4 messages...' when [messages.length] > 4
Cell createWalletTransferV3({
  required int seqno,
  required int sendMode,
  required int walletId,
  required List<MessageRelaxed> messages,
  required Uint8List privateKey,
  int? timeout,
}) {
  // Limit
  if (messages.length > 4) {
    throw 'Expected <= 4 messages, got ${messages.length}';
  }

  // Message
  var signingMsg = beginCell().storeUint(BigInt.from(walletId), 32);

  if (seqno == 0) {
    for (var i = 0; i < 32; i += 1) {
      signingMsg.storeBit(1);
    }
  } else {
    // 60 seconds from current timestamp
    var defaultTimeout = BigInt.from(
        (DateTime.now().millisecondsSinceEpoch / 1000).floor() + 60);
    signingMsg.storeUint(
        timeout == null ? defaultTimeout : BigInt.from(timeout), 32);
  }

  signingMsg.storeUint(BigInt.from(seqno), 32);
  for (var i = 0; i < messages.length; i += 1) {
    signingMsg.storeUint(BigInt.from(sendMode), 8);
    signingMsg.storeRef(beginCell().store(storeMessageRelaxed(messages[i])));
  }

  // Signature
  var signature = sign(signingMsg.endCell().hash(), privateKey);

  // Body
  final body =
      beginCell().storeList(signature).storeBuilder(signingMsg).endCell();

  return body;
}

/// Throws 'Expected <= 4 messages...' when [messages.length] > 4
Cell createWalletTransferV4({
  required int seqno,
  required int sendMode,
  required int walletId,
  required List<MessageRelaxed> messages,
  required Uint8List privateKey,
  int? timeout,
}) {
  // Limit
  if (messages.length > 4) {
    throw 'Expected <= 4 messages, got ${messages.length}';
  }

  // Message
  var signingMsg = beginCell().storeUint(BigInt.from(walletId), 32);

  if (seqno == 0) {
    for (var i = 0; i < 32; i += 1) {
      signingMsg.storeBit(1);
    }
  } else {
    // 60 seconds from current timestamp
    var defaultTimeout = BigInt.from(
        (DateTime.now().millisecondsSinceEpoch / 1000).floor() + 60);
    signingMsg.storeUint(
        timeout == null ? defaultTimeout : BigInt.from(timeout), 32);
  }

  signingMsg.storeUint(BigInt.from(seqno), 32);
  signingMsg.storeUint(BigInt.zero, 8); // Simple order

  for (var i = 0; i < messages.length; i += 1) {
    signingMsg.storeUint(BigInt.from(sendMode), 8);
    signingMsg.storeRef(beginCell().store(storeMessageRelaxed(messages[i])));
  }

  // Signature
  var signature = sign(signingMsg.endCell().hash(), privateKey);

  // Body
  final body =
      beginCell().storeList(signature).storeBuilder(signingMsg).endCell();

  return body;
}
