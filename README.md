# 💎 Dart/Flutter library for TON blockchain

A composable and versatile library for all things TON!

[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Pub](https://img.shields.io/pub/v/tonutils.svg)](https://pub.dartlang.org/packages/tonutils)

WARNING: Some underlying APIs of this library are subject to change in near future, so it's advised to pin down specific minor version rather than specifying ranges in your pubspec.yaml. At least until we hit stable 1.0.0 release.

---

If you love this library and want to support its development you can donate any amount of coins to this TON address ☺️`EQDew1rvHuMmMkmxG_fQahGymzIOF2_9TpgLftMUuxpKLE_u`\
To donate in other cryptocurrencies, use: <a href="https://github.com/novusnota/novusnota/blob/main/DONATE.md" alt="Donate button"><img src="https://img.shields.io/badge/-Donate-red?logo=undertale" /></a>

## 🍰 Features

- jsonRPC client to work with TON network: [lib/client](https://github.com/novusnota/tonutils-dart/blob/main/lib/client.dart)
- Cell, Slice, Builder, and BOC (de)serialization: [lib/dataformat](https://github.com/novusnota/tonutils-dart/blob/main/lib/dataformat.dart)
- Support for popular structures from block.tlb: [lib/dataformat](https://github.com/novusnota/tonutils-dart/blob/main/lib/dataformat.dart)
- Support of TON base64 addresses: [lib/dataformat](https://github.com/novusnota/tonutils-dart/blob/main/lib/dataformat.dart)
- Support of HashmapE: [lib/dataformat](https://github.com/novusnota/tonutils-dart/blob/main/lib/dataformat.dart)
- Support of TON & BIP39 Mnemonics: [lib/mnemonic](https://github.com/novusnota/tonutils-dart/blob/main/lib/mnemonic.dart)
- Support of wallets (v3, v3r2, v4r2): [lib/wallet](https://github.com/novusnota/tonutils-dart/blob/main/lib/wallet.dart)
- Ed25519 signing of transactions and crypto primitives: [lib/crypto](https://github.com/novusnota/tonutils-dart/blob/main/lib/crypto.dart)
- Workings with Jettons: [lib/jetton](https://github.com/novusnota/tonutils-dart/blob/main/lib/jetton.dart)
- Workings with NFTs: [lib/nft](https://github.com/novusnota/tonutils-dart/blob/main/lib/nft.dart)
- ...and much more!

## 🚀 Usage

### Install via `dart pub`:

```bash
dart pub add tonutils
```

### Get it all or use a few

Most common way is to import the whole library and cherry-pick the needed elements:

```dart
import 'package:tonutils/tonutils.dart' show Mnemonic;
```

Alternatively, consider using only the sub-libraries if you know precisely what you need:

```dart
import 'package:tonutils/mnemonic.dart'; // provides Mnemonic and WordList classes 
```

**All the individual things you can import and use are listed in the [root of lib/ folder](https://github.com/novusnota/tonutils-dart/tree/main/lib).**

### RPC Client (Toncenter API)

You can use one of the public endpoints:

- Mainnet: https://toncenter.com/api/v2/jsonRPC
- Testnet: https://testnet.toncenter.com/api/v2/jsonRPC

Or host [your own instance of TON HTTP API](https://github.com/toncenter/ton-http-api).

```dart
// Client uses testnet by default:
final testnetClient = TonJsonRpc();

// But you can specify an alternative endpoint, say, for mainnet:
final client = TonJsonRpc('https://toncenter.com/api/v2/jsonRPC');

// You can also specify an API key obtained from https://t.me/tonapibot!

// Generate a new key pair
var mnemonics = Mnemonic.generate();
var keyPair = Mnemonic.toKeyPair(mnemonics);

// Wallet contracts use workchain = 0, but this can be overriden
var wallet = WalletContractV4R2.create(publicKey: keyPair.publicKey);

// Opening a wallet contract (this specifies the TonJsonRpc as a ContractProvider)
var openedContract = client.open(wallet);

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
```

As you can see from this example, this library is 90% compatible with the API of the ton-core and ton-community TypeScript libraries. The main sources of divergence are types: this library uses sealed classes and extends from them to provide union-like types, while maintaining compile-time checked type safety and soundness.

But worry not — editor hints in VS Code, Emacs, Vim, NeoVim, Helix and other editors with Language Server Provider (LSP) support won't leave you astray and provide all the answers if you ever find yourself stuck.

### 📺 Videos

Playlist with examples on YouTube: [link](https://www.youtube.com/playlist?list=PLd8io4_DrUzlbG3SB89J1Eeq0VVdJh62R)

## 🔧 Tests

Tests are positioned to mirror the structure inside `lib/src/`, and grouped by the relative path from test folder to the test file (excluding the `_test.dart` suffix).

Examples:
- Tests for mnemonics are located in the file `test/mnemonic/mnemonic_test.dart`, and the test group name is `mnemonic/mnemonic`
- Tests for addresses are located in the file `test/dataformat/address/address_test.dart`, and the test group name is `dataformat/address/address`

To invoke a group of tests by their name, run:

```bash
dart test -N 'group name'
```

For example, to test mnemonics:

```bash
dart test -N 'mnemonic/mnemonic'
```

## 📄 License

Apache License 2.0
