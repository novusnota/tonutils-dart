import '../dataformat/address/api.dart' show InternalAddress;
import '../dataformat/contract/api.dart'
    show Contract, ContractABI, ContractInit, ContractProvider, CstActive;

/// IMPORTANT: Initialize the [provider] to use
class JettonWallet implements Contract {
  @override
  ContractABI? abi; // unused here

  @override
  InternalAddress address;

  @override
  ContractInit? init; // unused here

  @override
  ContractProvider? provider; // don't forget to initialize to use

  static JettonWallet create(InternalAddress address) {
    return JettonWallet(address);
  }

  JettonWallet(this.address, [this.provider]);

  /// Returns a balance of the jetton wallet as a Future<BigInt>
  ///
  /// Throws 'ContractProvider field was not initialized' if [provider] is null
  Future<BigInt> getBalance() async {
    if (provider == null) {
      throw 'ContractProvider field was not initialized';
    }
    var state = await provider!.getState();
    if (state.state is! CstActive) {
      return BigInt.zero;
    }
    var res = await provider!.get('get_wallet_data', []);
    return res.stack.readBigInt();
  }
}
