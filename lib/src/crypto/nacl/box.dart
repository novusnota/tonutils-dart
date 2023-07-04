// ignore: unnecessary_import
import 'dart:typed_data';

import 'package:pinenacl/x25519.dart';

Uint8List sealBox(Uint8List data, Uint8List nonce, Uint8List key) {
  var box = SecretBox(Uint8List.fromList(key));

  return box
      .encrypt(Uint8List.fromList(data), nonce: Uint8List.fromList(nonce))
      .toUint8List();
}

Uint8List openBox(Uint8List boxData, Uint8List key) {
  var box = SecretBox(Uint8List.fromList(key));
  var res = box.decrypt(EncryptedMessage.fromList(Uint8List.fromList(boxData)));

  return res;
}
