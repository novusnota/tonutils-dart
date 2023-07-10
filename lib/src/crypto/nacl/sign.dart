// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:pinenacl/ed25519.dart';

Uint8List sign(
  Uint8List data,
  Uint8List privateKey,
) {
  var signingKey = SigningKey.fromValidBytes(
    Uint8List.fromList(privateKey),
    keyLength: 64,
  );

  return signingKey.sign(Uint8List.fromList(data)).signature.toUint8List();
}

bool signVerify(
  Uint8List data,
  Uint8List signature,
  Uint8List publicKey,
) {
  var lSignature = Signature(signature);
  var verifyKey = VerifyKey(Uint8List.fromList(publicKey));

  return verifyKey.verify(signature: lSignature, message: data);
}
