import 'dart:typed_data';

import 'package:test/test.dart' show expect, group, test;
import 'package:tonutils/src/dataformat/bitstring/api.dart' show BitString;

void main() {
  group('dataformat/bitstring/bitstring', () {
    test('Reading bits', () {
      var b = BitString(
        Uint8List.fromList(
          [int.parse('10101010', radix: 2)],
        ),
        0,
        8,
      );

      expect(b.at(0), 1);
      expect(b.at(1), 0);
      expect(b.at(2), 1);
      expect(b.at(3), 0);
      expect(b.at(4), 1);
      expect(b.at(5), 0);
      expect(b.at(6), 1);
      expect(b.at(7), 0);
      expect(b.toString(), 'AA');
    });

    test('Equality check', () {
      var bits = int.parse('10101010', radix: 2);
      var a = BitString(Uint8List.fromList([bits]), 0, 8);
      var b = BitString(Uint8List.fromList([bits]), 0, 8);
      var c = BitString(Uint8List.fromList([0, bits]), 8, 8);

      expect(a.equals(b), true);
      expect(a.equals(c), true);
      expect(b.equals(c), true);

      expect(b.equals(a), true);
      expect(c.equals(b), true);

      expect(a.toString(), 'AA');
      expect(b.toString(), 'AA');
      expect(c.toString(), 'AA');
    });

    test('Formatting strings', () {
      expect(
        BitString(Uint8List.fromList([int.parse('00000000', radix: 2)]), 0, 1)
            .toString(),
        '4_',
      );
      expect(
        BitString(Uint8List.fromList([int.parse('10000000', radix: 2)]), 0, 1)
            .toString(),
        'C_',
      );
      expect(
        BitString(Uint8List.fromList([int.parse('11000000', radix: 2)]), 0, 2)
            .toString(),
        'E_',
      );
      expect(
        BitString(Uint8List.fromList([int.parse('11100000', radix: 2)]), 0, 3)
            .toString(),
        'F_',
      );
      expect(
        BitString(Uint8List.fromList([int.parse('11100000', radix: 2)]), 0, 4)
            .toString(),
        'E',
      );
      expect(
        BitString(Uint8List.fromList([int.parse('11101000', radix: 2)]), 0, 5)
            .toString(),
        'EC_',
      );
    });

    test('Sublists', () {
      var b1 = BitString(Uint8List.fromList([1, 2, 3, 4, 5, 6, 7, 8]), 0, 64);
      var b2 = b1.sublist(0, 16);

      expect(b2!.length, 2);
    });
  });
}
