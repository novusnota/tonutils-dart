import '../dataformat/address/api.dart' show InternalAddress;
import '../dataformat/cell/api.dart' show Cell, beginCell;
import '../dataformat/contract/api.dart'
    show Contract, ContractABI, ContractInit, ContractProvider;
import '../dataformat/tuple/api.dart' show TiSlice;

/// IMPORTANT: Initialize the [provider] to use
class JettonMaster implements Contract {
  @override
  ContractABI? abi; // unused here

  @override
  InternalAddress address;

  @override
  ContractInit? init; // unused here

  @override
  ContractProvider? provider; // don't forget to initialize to use

  static JettonMaster create(InternalAddress address) {
    return JettonMaster(address);
  }

  JettonMaster(this.address, [this.provider]);

  /// Returns a jetton wallet address a Future<InternalAddress>
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<InternalAddress> getWalletAddress(InternalAddress owner) async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    var res = await provider!.get(
      'get_wallet_address',
      [TiSlice(beginCell().storeAddress(owner).endCell())],
    );

    return res.stack.readAddress();
  }

  /// Returns a jetton data as a record
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<
      ({
        BigInt totalSupply,
        bool mintable,
        InternalAddress adminAddress,
        Cell content,
        Cell walletCode,
      })> getJettonData() async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    var res = await provider!.get('get_jetton_data', []);
    var totalSupply = res.stack.readBigInt();
    var mintable = res.stack.readBool();
    var adminAddress = res.stack.readAddress();
    var content = res.stack.readCell();
    var walletCode = res.stack.readCell();

    return (
      totalSupply: totalSupply,
      mintable: mintable,
      adminAddress: adminAddress,
      content: content,
      walletCode: walletCode,
    );
  }
}
