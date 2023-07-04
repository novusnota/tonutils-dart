// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:pinenacl/ed25519.dart';

/// ```dart
/// ({
///   Uint8List publicKey,
///   Uint8List privateKey,
/// })
/// ```
class KeyPair {
  Uint8List publicKey;
  Uint8List privateKey;

  KeyPair({
    required this.publicKey,
    required this.privateKey,
  });

  static KeyPair fromPrivateKey(Uint8List privateKey) {
    var key = SigningKey.fromValidBytes(
      Uint8List.fromList(privateKey),
      keyLength: 64,
    );

    return KeyPair(
      publicKey: key.publicKey.toUint8List(),
      privateKey: key.toUint8List(),
    );
  }

  static KeyPair fromSeed(Uint8List seed) {
    var key = SigningKey.fromSeed(Uint8List.fromList(seed));

    return KeyPair(
      publicKey: key.publicKey.toUint8List(),
      privateKey: key.toUint8List(),
    );
  }
}
