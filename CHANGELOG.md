# CHANGELOG

## 0.5.6

Bugfix of methods of Nano class

## 0.5.5

Bugfix of internal function _parseCallGetMethod: [issue](https://github.com/novusnota/tonutils-dart/issues/2)

Misc:
- Better usage of Cell.fromBocBase64 function
- Updated wallet address for TonJsonRpc tests

## 0.5.4

Bugfix of crypto sign, signVerify and safeSign functions: [issue](https://github.com/novusnota/tonutils-dart/issues/1)

## 0.5.3

Lowered version of `collection` library from `1.17.2` to `1.17.1` to improve compatibility with the current Flutter SDK version

## 0.5.2

Version bump for pub.dev re-evaluation

## 0.5.1

Minor fixes for pub.dev upload

## 0.5.0

Minor release for the semver, major release for the community!

Milestones hit:
- [x] Support of Jettons and NFTs

Notes:
Fully implemented the [ton-footstep](https://github.com/ton-society/ton-footsteps/issues/224). A big thanks for the patience of everyone involved and a big sorry — for the delays.

It's already a very broad and useful SDK that is capable for bringing the Dart/Flutter and TON Blockchain together. And I will continue updating this library, so that it would bring even more value to both ecosystems!

Looking forward to projects built using this SDK :)

Plans for future development:
- Better unit test coverage
- More examples/tutorials
- Caching for TonJsonRpc, especially for shards and shard transactions
- DNS resolutions, especially using Ton Domains as wallet address shorthands
- ADNL client
- ...and a lot more — stay tuned!

## 0.4.4

- Updated `README.md`:
  - added a link to YouTube playlist with examples
  - added more examples of usage
  - overall polishing
- Added a new example: `jsonrpc_example.dart`
- Bug fixes for `client/`
- Bug fixes for `dataformat/cell/`
- Bug fixes for `dataformat/bitstring/`
- Bug fixes for `dataformat/address/`
- Bug fixes for `dataformat/type/`

## 0.4.3

- Covered `client/` with tests
- Covered `dataformat/bitstring/` with tests
- Added tests for `dataformat/address/`
- Added tests for `dataformat/type/`
- Added tests for `dataformat/cell/`
- Added a chapter on running tests in the `README.md`

## 0.4.2

Non-fungible tokens (NFTs)

- Added to `nft/`:
  - `collection.dart`
  - `item.dart`
  - `collection_royalty.dart`
  - `item_royalty.dart`

## 0.4.1

Jettons – Fungible tokens (FTs)

- Added to `jetton/`
  - `jetton_master.dart`
  - `jetton_wallet.dart`

## 0.4.0

Minor release.

Milestones hit:
- [x] Support of wallets (v3, v3r2, v4r2)
- [x] RPC client to work with the TON network
- [x] Ed25519 signing of transactions

More to `crypto/`:
- Low-level crypto primitives
- Bug fix: incorrect CRC16 checks

More to `dataformat/address/`:
- Bug fix: incorrect parsing of friendly internal addresses

Extras:
- Miscellaneous small improvements throughout the SDK
- Added a `LICENSE`

## 0.3.3

Milestone: RPC client to work with the TON network

- Added to `client/`:
  - `client.dart`
  - `cache.dart`
- Covered `client/` with tests

## 0.3.2

Milestone: Support of wallets (v3, v3r2, v4r2)

- Added to `wallet/`:
  - `v3r1.dart`
  - `v3r2.dart`
  - `v4r2.dart`
- Added to `wallet/utils`:
  - `create_wallet_transfer.dart`

## 0.3.1

Milestone: Ed25519 signing of transactions

- Added to `crypto/nacl/`:
  - `key_pair.dart`
  - `sign.dart`
  - `box.dart`
- Added to `crypto/utils/`:
  - `safe_sign.dart`

## 0.3.0

Minor release.

Milestones hit:
- [x] Support of HashmapE
- [x] Support for popular structures from block.tlb

More to `dataformat/address/utils.dart`:
- function contractAddress

More to `dataformat/cell`:
- dictionary-related methods in Builder and Slice

## 0.2.2

Milestone: Support for popular structures from block.tlb

- Added to `dataformat/type/`:
  - `send_mode.dart`
  - `currency_collection.dart`
  - `common_message_info.dart`
  - `common_message_info_relaxed.dart`
  - `simple_library.dart`
  - `tick_tock.dart`
  - `state_init.dart`
  - `message.dart`
  - `message_relaxed.dart`
  - `account_status.dart`
  - `account_status_change.dart`
  - `hash_update.dart`
  - `split_merge_info.dart`
  - `storage_used_short.dart`
  - `transaction_action_phase.dart`
  - `transaction_bounce_phase.dart`
  - `compute_skip_reason.dart`
  - `transaction_compute_phase.dart`
  - `transaction_credit_phase.dart`
  - `transaction_storage_phase.dart`
  - `transaction_description.dart`
  - `transaction.dart`
- Added to `dataformat/type/utils/`:
  - `helpers.dart`
  - `unions.dart`
- Added to `dataformat/address/utils.dart`:
  - function contractAddress

## 0.2.1

Milestone: Support of HashmapE

- Added to `dataformat/dictionary/`:
  - `dictionary.dart`
- Added to `dataformat/dictionary/utils/`
  - `parse.dart`
  - `serialize.dart`
  - `key_serialization.dart`
  - `find_common_prefix.dart`
- Added dictionary-related methods to:
  - `dataformat/cell/`
  - `dataformat/cell/utils/`
  
## 0.2.0

Minor release.

Milestones hit:
- [x] Cell, Slider, Builder, BoC (de)serialization

Nano:
- class Nano

More to `crypto/`:
- class Crc32c
- method Crc16.getMethodId

Tuples:
- classes TupleItem: TiTuple, TiNull, TiInt, TiNan, TiCell, TiBuilder;
- functions parseTuple, serializeTuple
- classes TupleReader, TupleBuilder

Contracts:
- `compute_error.dart`
- `contract.dart`
- `contract_abi.dart`
- `contract_provider.dart`
- `contract_state.dart`
- `sender.dart`

## 0.1.6

Contracts

- Added to `dataformat/contract/`:
  - `compute_error.dart`
  - `contract.dart`
  - `contract_abi.dart`
  - `contract_provider.dart`
  - `contract_state.dart`
  - `sender.dart`

## 0.1.5

Tuples 

- Added to `dataformat/tuple/`:
  - `tuple.dart`
  - `reader.dart`
  - `builder.dart`

## 0.1.4

Milestone: Cell, Slice, Builder, BoC (de)serialization

- Added to `dataformat/cell/`:
  - `levelmask.dart`
  - `cell.dart`
  - `builder.dart`
  - `slice.dart`
  - `boc.dart`
- Added to `dataformat/cell/utils`:
  - `descriptors.dart`
  - `strings.dart`
  - `topological_sort.dart`
  - `exotics.dart`
  - `wonder_calculator.dart`

## 0.1.3

CRC extras

- Added to `crypto/crc/`:
  - New public method for Crc16: `getMethodId`
  - `crc32c.dart`

## 0.1.2

Nano

- Added to `dataformat/nano/`:
  - `nano.dart`

## 0.1.1

TON-specific BitString

- Added to `dataformat/bitstring/`:
  - `bitstring.dart`
  - `bitbuilder.dart`
  - `bitreader.dart`

## 0.1.0

Minor release:

- [x] Support of TON & BIP39 mnemonics
- [x] Support of TON base64 addresses
- Crc16

## 0.0.5

Milestone: Support of TON base64 addresses

- New lib: dataformat/
- Added `dataformat/address.dart`

## 0.0.4

- New lib: crypto/
- Added `crypto/crc/crc16.dart`

## 0.0.3

- Passing tests for `mnemonic.dart`

## 0.0.2

Milestone: Support of TON & BIP39 mnemonics

- Added `mnemonic.dart` and `src/mnemonic`
- Covered `mnemonic.dart` with tests

## 0.0.1

- Initial version.
