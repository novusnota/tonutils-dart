import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:test/test.dart' show expect, group, test;
import 'package:tonutils/tonutils.dart' show InternalAddress;

void main() {
  group('dataformat/address/address', () {
    test('Parses in friendly form', () {
      var friendlyAddr1 = InternalAddress.parseFriendly(
          '0QAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4-QO');
      var friendlyAddr2 = InternalAddress.parseFriendly(
          'kQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi47nL');

      expect(friendlyAddr1.isBounceable, false);
      expect(friendlyAddr2.isBounceable, true);

      expect(friendlyAddr1.isTestOnly, true);
      expect(friendlyAddr2.isTestOnly, true);

      expect(friendlyAddr1.address.workChain, BigInt.zero);
      expect(friendlyAddr2.address.workChain, BigInt.zero);

      var friendlyHex1 =
          '2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3';
      var friendlyHash1 = Uint8List.fromList(hex.decode(friendlyHex1));

      var friendlyHex2 =
          '2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3';
      var friendlyHash2 = Uint8List.fromList(hex.decode(friendlyHex2));

      expect(friendlyAddr1.address.hash.equals(friendlyHash1), true);
      expect(friendlyAddr2.address.hash.equals(friendlyHash2), true);

      expect(friendlyAddr1.address.toRawString(), '0:$friendlyHex1');
      expect(friendlyAddr2.address.toRawString(), '0:$friendlyHex2');
    });

    test('Parses in raw form', () {
      var rawAddr = InternalAddress.parseRaw(
          '0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3');

      expect(rawAddr.workChain, BigInt.zero);

      var rawHex =
          '2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3';
      var rawHash = Uint8List.fromList(hex.decode(rawHex));

      expect(rawAddr.hash.equals(rawHash), true);
      expect(rawAddr.toRawString(), '0:$rawHex');
    });

    test('Serializes to friendly form', () {
      var address = InternalAddress.parseRaw(
          '0:2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3');

      // Bounceable
      expect(
        address.toString(),
        'EQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4wJB',
      );
      expect(
        address.toString(isTestOnly: true),
        'kQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi47nL',
      );
      expect(
        address.toString(isUrlSafe: false),
        'EQAs9VlT6S776tq3unJcP5Ogsj+ELLunLXuOb1EKcOQi4wJB',
      );
      expect(
        address.toString(isUrlSafe: false, isTestOnly: true),
        'kQAs9VlT6S776tq3unJcP5Ogsj+ELLunLXuOb1EKcOQi47nL',
      );

      // Non-bounceable
      expect(
        address.toString(isBounceable: false),
        'UQAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi41-E',
      );
      expect(
        address.toString(isBounceable: false, isTestOnly: true),
        '0QAs9VlT6S776tq3unJcP5Ogsj-ELLunLXuOb1EKcOQi4-QO',
      );
      expect(
        address.toString(isBounceable: false, isUrlSafe: false),
        'UQAs9VlT6S776tq3unJcP5Ogsj+ELLunLXuOb1EKcOQi41+E',
      );
      expect(
        address.toString(
          isBounceable: false,
          isUrlSafe: false,
          isTestOnly: true,
        ),
        '0QAs9VlT6S776tq3unJcP5Ogsj+ELLunLXuOb1EKcOQi4+QO',
      );
    });

    test('Equality checks', () {
      var hexAddr =
          '2cf55953e92efbeadab7ba725c3f93a0b23f842cbba72d7b8e6f510a70e422e3';

      var address1 = InternalAddress.parseRaw('0:$hexAddr');
      var address2 = InternalAddress.parseRaw('0:$hexAddr');
      var address3 = InternalAddress.parseRaw('-1:$hexAddr');
      var address4 = InternalAddress.parseRaw(
        '0:${hexAddr.replaceAll(RegExp(r'3'), '5')}',
      );

      // first is second
      expect(address1.equals(address2), true);
      // second is first
      expect(address2.equals(address1), true);

      // first != third or fourth
      expect(address1.equals(address3), false);
      expect(address1.equals(address4), false);

      // second != third or fourth
      expect(address2.equals(address3), false);
      expect(address2.equals(address4), false);

      // third != fourth
      expect(address3.equals(address4), false);
    });
  });
}
