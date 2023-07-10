import 'dart:convert';
import 'dart:typed_data';

import 'package:pointycastle/digests/sha256.dart';

import '../../dataformat/cell/api.dart' show Cell;
import '../nacl/api.dart' show sign, signVerify;

const int _minSeedLength = 8;
const int _maxSeedLength = 64;
const String _defaultSeed = 'ton-safe-sign-magic';

Uint8List _createSafeSignHash(Cell cell, String seed) {
  var seedData = Uint8List.fromList(utf8.encode(seed));
  if (seedData.length > _maxSeedLength) {
    throw 'Seed can not be longer than 64 bytes, got ${seedData.length}';
  }
  if (seedData.length < _minSeedLength) {
    throw 'Seed can not be less than 8 bytes, got ${seedData.length}';
  }

  var bb = BytesBuilder();
  bb.add(Uint8List.fromList(<int>[0xff, 0xff]));
  bb.add(seedData);
  bb.add(cell.hash());

  return SHA256Digest().process(bb.takeBytes());
}

/// Returns a signature as Uint8List from the hash of [cell] and [ceed] and a [privateKey]
Uint8List safeSign(Cell cell, Uint8List privateKey,
    [String seed = _defaultSeed]) {
  return sign(_createSafeSignHash(cell, seed), privateKey);
}

/// Returns true if hash from [cell] and [seed] confirms to the [signature] and [publicKey], and false otherwise
bool safeSignVerify(Cell cell, Uint8List signature, Uint8List publicKey,
    [String seed = _defaultSeed]) {
  return signVerify(_createSafeSignHash(cell, seed), signature, publicKey);
}
