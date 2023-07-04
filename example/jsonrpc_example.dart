import 'dart:io';

import 'package:tonutils/tonutils.dart'
    show
        Mnemonic,
        SbiString,
        ScString,
        SiaString,
        TonJsonRpc,
        WalletContractV4R2,
        internal;

void main() async {
  // Client uses testnet by default:
  // final testnetClient = TonJsonRpc();

  // But you can specify an alternative endpoint, say for mainnet
  // final client = TonJsonRpc('https://toncenter.com/api/v2/jsonRPC');

  // Consider getting an API key for TON HTTP API before running this example,
  // as requests from client may easily get over rate limit:
  var apiKeyMainnet =
      File('../.api_key_mainnet').readAsStringSync().trim().toLowerCase();

  final client = TonJsonRpc(
    'https://toncenter.com/api/v2/jsonRPC',
    apiKeyMainnet.isNotEmpty ? apiKeyMainnet : null,
  );

  // Generate a new key pair
  var mnemonics = Mnemonic.generate();
  var keyPair = Mnemonic.toKeyPair(mnemonics);

  // Wallet contracts use workchain = 0, but this can be overriden
  var wallet = WalletContractV4R2.create(publicKey: keyPair.publicKey);

  // Opening a wallet contract (this specifies the TonJsonRpc as a ContractProvider)
  var openedContract = client.open(wallet);
  assert(openedContract.provider != null);

  // Get the balance of the contract
  var balance = await openedContract.getBalance();
  print(balance);

  // Create a transfer
  var seqno = await openedContract.getSeqno();
  var transfer = openedContract.createTransfer(
    seqno: seqno,
    privateKey: keyPair.privateKey,
    messages: [
      internal(
        to: SiaString('EQCD39VS5jcptHL8vMjEXrzGaRcCVYto7HUn4bpAOg8xqB2N'),
        value: SbiString('1.5'),
        body: ScString('Hello, world!'),
      )
    ],
  );
  print(transfer.toString());

  // As you can see from this example, this library is 90% compatible with the API of the ton-core and ton-community TypeScript libraries
  // The main sources of divergence are types: this library uses sealed classes and extends from them to maintain compile-time checked type safety and soundness.
  // Editor hints in VS Code, Emacs, Vim, NeoVim, Helix and other editors with Language Server Provider (LSP) support won't leave you astray and provide all the answers if you ever find yourself stuck :)
}
