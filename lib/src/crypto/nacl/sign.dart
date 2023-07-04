// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:pinenacl/ed25519.dart';

Uint8List sign(Uint8List data, Uint8List privateKey) {
  var signingKey = SigningKey.fromValidBytes(
    Uint8List.fromList(privateKey),
    keyLength: 64,
  );

  return signingKey.sign(Uint8List.fromList(data)).toUint8List();
}

bool signVerify(Uint8List signedData, Uint8List publicKey) {
  var verifyKey = VerifyKey(Uint8List.fromList(publicKey));

  return verifyKey.verifySignedMessage(
      signedMessage: SignedMessage.fromList(
          signedMessage: Uint8List.fromList(signedData)));
}
