import '../dataformat/address/api.dart' show InternalAddress;
import '../dataformat/cell/api.dart' show beginCell;
import '../dataformat/contract/api.dart' show Sender;
import '../dataformat/type/api.dart' show SbiBigInt, ScCell, SendMode;

import 'api.dart' show NftCollection;

/// Represents a collection of NFT items with royalty features
/// IMPORTANT: Initialize the [provider] to use
class NftCollectionRoyalty extends NftCollection {
  /// Constructs an instance of the NftCollectionRoyalty contract
  /// [address] — address of the contract
  /// [init] — optional initialization data for the contract's code and data
  NftCollectionRoyalty(super.address, [super.init]);

  /// Returns a new NftCollectionRoyalty from the InternalAddress [address]
  static NftCollectionRoyalty createFromAddress(InternalAddress address) {
    return NftCollectionRoyalty(address);
  }

  /// Returns nothing, sends a request to get the royalty parameters from the contract
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<void> sendGetRoyaltyParams(
    Sender via, {
    required BigInt value,
    required BigInt queryId,
  }) async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    var lValue = SbiBigInt(value);
    var body = ScCell(beginCell()
        .storeUint(BigInt.from(0x693d3950), 32)
        .storeUint(queryId, 64)
        .endCell());

    await provider!.internal(
      via,
      value: lValue,
      body: body,
      sendMode: SendMode.payGasSeparately,
    );
  }

  /// Returns the royalty parameters of the NFT collection from the contract as a record, wrapped in a Future:
  /// ```dart
  /// Future<({
  ///   bool init,
  ///   BigInt numerator,
  ///   BigInt denominator,
  ///   InternalAddress? destination,
  /// })>
  /// ```
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<
      ({
        bool init,
        BigInt numerator,
        BigInt denominator,
        InternalAddress? destination,
      })> getRoyaltyParams() async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    final res = await provider!.get('royalty_params', []);
    var init = res.stack.readBool();
    var numerator = res.stack.readBigInt();
    var denominator = res.stack.readBigInt();
    var destination = res.stack.readAddressOrNull();

    return (
      init: init,
      numerator: numerator,
      denominator: denominator,
      destination: destination,
    );
  }
}
