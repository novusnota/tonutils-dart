import 'dart:convert';
import 'dart:math';
// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:pinenacl/ed25519.dart';
import 'package:pointycastle/api.dart';
import 'package:pointycastle/key_derivators/api.dart';
import 'package:tonutils/src/crypto/nacl/api.dart';

import 'wordlist.dart';

sealed class Mnemonic {
  static const wordsCount = 24;

  static final random = Random.secure();

  static final _kdDefaultSeed = KeyDerivator('SHA-512/HMAC/PBKDF2')
    ..init(Pbkdf2Parameters(_strToBytes('TON default seed'), 100000, 64));

  static final _kdBasicSeed = KeyDerivator('SHA-512/HMAC/PBKDF2')
    ..init(Pbkdf2Parameters(
        _strToBytes('TON seed version'), 390, 64)); // 100000 ~/ 256

  static final _kdFastSeed = KeyDerivator('SHA-512/HMAC/PBKDF2')
    ..init(Pbkdf2Parameters(_strToBytes('TON fast seed version'), 1, 64));

  static List<String> generate([String password = '']) {
    var isPassword = password.isNotEmpty;
    var randomValueLimit = WordList.bip39English.length;
    var mnemonic = <String>[];

    while (true) {
      var randomIndexes = <int>[];
      while (randomIndexes.length < wordsCount) {
        var randomIndex = random.nextInt(randomValueLimit);
        if (randomIndexes.contains(randomIndex)) {
          continue;
        }
        randomIndexes.add(randomIndex);
      }

      mnemonic = <String>[];
      for (var i = 0; i < randomIndexes.length; i += 1) {
        mnemonic.add(WordList.bip39English[randomIndexes[i]]);
      }

      if (isPassword && !isPasswordNeeded(mnemonic)) {
        continue;
      }

      if (!isBasicSeed(toEntropy(mnemonic, password))) {
        continue;
      }

      break;
    }
    return mnemonic;
  }

  static bool isPasswordNeeded(List<String> mnemonic) {
    var entropy = toEntropy(mnemonic, '');

    return isPasswordSeed(entropy) && !isBasicSeed(entropy);
  }

  static bool isValid(List<String> mnemonic, [String password = '']) {
    for (var i = 0; i < mnemonic.length; i += 1) {
      if (!WordList.bip39English.contains(mnemonic[i])) {
        return false;
      }
    }

    if (password.isNotEmpty && !isPasswordNeeded(mnemonic)) {
      return false;
    }

    return isBasicSeed(toEntropy(mnemonic, password));
  }

  static bool isBasicSeed(Uint8List entropy) {
    var seed64 = _kdBasicSeed.process(entropy);
    if (seed64.isEmpty) throw 'Couldn\'t generate basic seed';

    return seed64.first == 0;
  }

  static bool isPasswordSeed(Uint8List entropy) {
    var seed64 = _kdFastSeed.process(entropy);
    if (seed64.isEmpty) throw 'Couldn\'t generate fast seed';

    return seed64.first == 1;
  }

  static Uint8List toEntropy(List<String> mnemonic, [String password = '']) {
    var phrase = _strToBytes(mnemonic.join(' '));
    var hmac = Mac("SHA-512/HMAC")..init(KeyParameter(phrase));

    return hmac.process(_strToBytes(password));
  }

  static Uint8List toSeed64(List<String> mnemonic, [String password = '']) {
    var entropy = toEntropy(mnemonic, password);

    return _kdDefaultSeed.process(entropy);
  }

  static Uint8List toSeed32(List<String> mnemonic, [String password = '']) {
    var seed64 = toSeed64(mnemonic, password);

    return Uint8List.fromList(seed64.take(32).toList(growable: false));
  }

  static KeyPair toKeyPair(List<String> mnemonic, [String password = '']) {
    var seed32 = toSeed32(mnemonic, password);
    var key = SigningKey(seed: seed32);

    return KeyPair(
      publicKey: key.publicKey.toUint8List(),
      privateKey: key.toUint8List(),
    );
  }

  static Uint8List _strToBytes(String data) {
    return Uint8List.fromList(utf8.encode(data));
  }
}
