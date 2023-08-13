import 'dart:typed_data';

import '../dataformat/address/api.dart' show InternalAddress, contractAddress;
import '../dataformat/cell/api.dart' show beginCell, Cell;
import '../dataformat/contract/api.dart'
    show
        Contract,
        ContractABI,
        ContractInit,
        ContractProvider,
        CstActive,
        Sender;
import '../dataformat/type/api.dart'
    show
        MessageRelaxed,
        SbiBigInt,
        ScCell,
        SendMode,
        SiaInternalAddress,
        StateInit,
        internal;
import 'utils/api.dart' show createWalletTransferV3;

/// IMPORTANT: Initialize the [provider] to use
class WalletContractV3R1 implements Contract {
  @override
  ContractABI?
      abi; // required from 'implements Contract', unused in this wallet

  @override
  late InternalAddress address;

  @override
  ContractInit? init;

  @override
  ContractProvider? provider; // don't forget to initialize to use

  late int walletId;
  int workChain;
  Uint8List publicKey;

  /// Returns a new instance of a WalletContractV3R1
  static WalletContractV3R1 create({
    required Uint8List publicKey,
    int workChain = 0,
    int? walletId,
  }) {
    return WalletContractV3R1(publicKey, workChain, walletId);
  }

  WalletContractV3R1(this.publicKey, [this.workChain = 0, int? walletId]) {
    this.walletId = walletId ?? 698983191 + workChain;
    final encodedCell =
        'te6cckEBAQEAYgAAwP8AIN0gggFMl7qXMO1E0NcLH+Ck8mCDCNcYINMf0x/TH/gjE7vyY+1E0NMf0x/T/9FRMrryoVFEuvKiBPkBVBBV+RDyo/gAkyDXSpbTB9QC+wDo0QGkyMsfyx/L/8ntVD++buA=';

    var code = Cell.fromBocBase64(encodedCell);
    var data = beginCell()
        .storeUint(BigInt.zero, 32) // Seqno: 0
        .storeUint(BigInt.from(this.walletId), 32)
        .storeList(publicKey)
        .endCell();
    init = ContractInit(code: code, data: data);
    address = contractAddress(workChain, StateInit(null, null, code, data));
  }

  /// Returns the balance of the wallet as a Future<BigInt>
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<BigInt> getBalance() async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    var state = await provider!.getState();

    return state.balance;
  }

  /// Returns the sequence number of the wallet as a Future<int>
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<int> getSeqno() async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    var state = await provider!.getState();
    if (state.state is! CstActive) {
      return 0;
    }
    var res = await provider!.get('seqno', []);
    return res.stack.readInt();
  }

  /// Returns nothing, sends a signed transfer
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<void> send(Cell message) async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    await provider!.external(message);
  }

  /// Returns nothing, signs and sends the transfer
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<void> sendTransfer({
    required int seqno,
    required Uint8List privateKey,
    required List<MessageRelaxed> messages,
    SendMode? sendMode,
    int? timeout,
  }) async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    var transfer = createTransfer(
      seqno: seqno,
      privateKey: privateKey,
      messages: messages,
      sendMode: sendMode,
      timeout: timeout,
    );
    await send(transfer);
  }

  /// Returns a wallet transfer as a Cell
  Cell createTransfer({
    required int seqno,
    required Uint8List privateKey,
    required List<MessageRelaxed> messages,
    SendMode? sendMode,
    int? timeout,
  }) {
    var transferSendMode = sendMode ?? SendMode.payGasSeparately;
    return createWalletTransferV3(
      seqno: seqno,
      sendMode: transferSendMode.value,
      walletId: walletId,
      messages: messages,
      privateKey: privateKey,
      timeout: timeout,
    );
  }

  /// Returns a Sender
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  createSender(Uint8List privateKey) {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    return Sender(
      send: (args) async {
        var seqno = await getSeqno();
        var transfer = createTransfer(
            seqno: seqno,
            privateKey: privateKey,
            sendMode: args.sendMode,
            messages: <MessageRelaxed>[
              internal(
                  to: SiaInternalAddress(args.to),
                  value: SbiBigInt(args.value),
                  init: args.init,
                  body: args.body == null ? null : ScCell(args.body!),
                  bounce: args.bounce)
            ]);
        await send(transfer);
      },
    );
  }
}
