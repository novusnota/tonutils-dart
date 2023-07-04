import '../dataformat/address/api.dart' show InternalAddress;
import '../dataformat/cell/api.dart' show Cell, beginCell;
import '../dataformat/contract/api.dart'
    show Contract, ContractABI, ContractInit, ContractProvider, Sender;
import '../dataformat/type/api.dart'
    show
        CmiInternal,
        SbiBigInt,
        ScCell,
        SendMode,
        TcpVm,
        TdGeneric,
        Transaction;

/// Represents an NFT item contract
/// Initialize the [provider] to use
class NftItem implements Contract {
  @override
  ContractABI? abi; // required from 'implements Contract', unused here

  @override
  InternalAddress address;

  @override
  ContractInit? init;

  @override
  ContractProvider? provider; // don't forget to initialize to use

  /// Constructs an instance of the NftItem contract
  /// [address] — address of the contract
  /// [init] — optional initialization data for the contract's code and data
  NftItem(this.address, [this.init]);

  /// Returns a NftTransfer? from the parsed transaction [tx]
  static NftTransfer? parseTransfer(Transaction tx) {
    try {
      final body = tx.inMessage?.body.beginParse();
      if (body == null) {
        return null;
      }

      final op = body.loadUint(32);
      if (op != 0x5fcc3d14) {
        return null;
      }

      // Eligibility check
      if ((tx.inMessage?.info is CmiInternal) == false) {
        return null;
      }
      if ((tx.description is TdGeneric) == false) {
        return null;
      }
      if (((tx.description as TdGeneric).computePhase is TcpVm) == false) {
        return null;
      }
      if (((tx.description as TdGeneric).computePhase as TcpVm).exitCode != 0) {
        return null;
      }

      // NftTransfer instance
      var queryId = body.loadUint(64);
      var from = (tx.inMessage!.info as CmiInternal).src;
      var to = body.loadInternalAddress();
      var responseTo = body.loadInternalAddressOrNull();
      var customPayload = body.loadRef();
      var forwardAmount = body.loadCoins();
      var forwardPayload = body.loadRef();

      return NftTransfer(
        queryId: queryId,
        from: from,
        to: to,
        responseTo: responseTo,
        customPayload: customPayload,
        forwardAmount: forwardAmount,
        forwardPayload: forwardPayload,
      );
    } catch (e) {
      return null;
    }
  }

  /// Returns nothing, sends a transfer (internal message) from the contract
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<void> sendTransfer(
    Sender via, {
    required BigInt value,
    required BigInt queryId,
    required InternalAddress newOwner,
    required InternalAddress responseDestination,
    Cell? customPayload,
    required BigInt forwardAmount,
    Cell? forwardPayload,
  }) async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    var body = beginCell()
        .storeUint(BigInt.from(0x5fcc3d14), 32)
        .storeUint(queryId, 64)
        .storeAddress(newOwner)
        .storeAddress(responseDestination)
        .storeMaybeRef(customPayload)
        .storeCoins(forwardAmount)
        .storeMaybeRef(forwardPayload)
        .endCell();

    await provider!.internal(
      via,
      value: SbiBigInt(value),
      body: ScCell(body),
      sendMode: SendMode.payGasSeparately,
    );
  }

  /// Returns nothing, sends static data from the contract
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<void> sendGetStaticData(
    Sender via, {
    required BigInt value,
    required BigInt queryId,
  }) async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    var body = beginCell()
        .storeUint(BigInt.from(0x2fcb26a2), 32)
        .storeUint(queryId, 64) // || 0?
        .endCell();

    await provider!.internal(
      via,
      value: SbiBigInt(value),
      body: ScCell(body),
      sendMode: SendMode.payGasSeparately,
    );
  }

  /// Returns the NFT data from the contract as a record, wrapped in a Future:
  /// ```dart
  /// Future<({
  ///   bool init,
  ///   BigInt index,
  ///   InternalAddress? collectionAddress,
  ///   InternalAddress? ownerAddress,
  ///   Cell? individualContent,
  /// })>
  /// ```
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<
      ({
        bool init,
        BigInt index,
        InternalAddress? collectionAddress,
        InternalAddress? ownerAddress,
        Cell? individualContent,
      })> getNftData() async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    final res = await provider!.get('get_nft_data', []);
    var init = res.stack.readBool();
    var index = res.stack.readBigInt();
    var collectionAddress = res.stack.readAddressOrNull();
    var ownerAddress = res.stack.readAddressOrNull();
    var individualContent = res.stack.readCellOrNull();

    return (
      init: init,
      index: index,
      collectionAddress: collectionAddress,
      ownerAddress: ownerAddress,
      individualContent: individualContent,
    );
  }
}

/// ```dart
/// ({
///   int queryId,
///   Address? from,
///   InternalAddress to,
///   InternalAddress? responseTo,
///   Cell customPayload,
///   BigInt forwardAmount,
///   Cell forwardPayload,
/// })
/// ```
class NftTransfer {
  int queryId;
  InternalAddress from;
  InternalAddress to;
  InternalAddress? responseTo;
  Cell customPayload;
  BigInt forwardAmount;
  Cell forwardPayload;

  NftTransfer({
    required this.queryId,
    required this.from,
    required this.to,
    this.responseTo,
    required this.customPayload,
    required this.forwardAmount,
    required this.forwardPayload,
  });
}
