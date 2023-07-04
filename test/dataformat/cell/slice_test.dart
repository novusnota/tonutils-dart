import 'dart:math';
import 'dart:typed_data';

import 'package:collection/collection.dart';
import 'package:test/test.dart' show expect, group, test;
import 'package:tonutils/tonutils.dart' show BitBuilder, Cell, InternalAddress;

const threePrimes = 2 * 2351 * 4513;
const bitLength = 25;
// see: https://numbermatics.com/n/281474976710654/

void main() {
  group('dataformat/cell/slice', () {
    test('Reading uints from slice', () {
      var prando = Random('test-1'.codeUnits.sum);
      for (var i = 0; i < 1000; i += 1) {
        var a = prando.nextInt(threePrimes + 1);
        var b = prando.nextInt(threePrimes + 1);
        var builder = BitBuilder();

        builder.writeUint(BigInt.from(a), bitLength);
        builder.writeUint(BigInt.from(b), bitLength);

        var bits = builder.build();

        {
          var reader = Cell(bits: bits).beginParse();
          expect(reader.preloadUint(bitLength), a);
          expect(reader.loadUint(bitLength), a);
          expect(reader.preloadUint(bitLength), b);
          expect(reader.loadUint(bitLength), b);
        }
        {
          var reader = Cell(bits: bits).beginParse();
          expect(reader.preloadUintBig(bitLength).toInt(), a);
          expect(reader.loadUintBig(bitLength).toInt(), a);
          expect(reader.preloadUintBig(bitLength).toInt(), b);
          expect(reader.loadUintBig(bitLength).toInt(), b);
        }
      }
    });

    test('Reading ints from slice', () {
      var prando = Random('test-2'.codeUnits.sum);
      for (var i = 0; i < 1000; i += 1) {
        var a =
            -prando.nextInt(threePrimes + 1) + prando.nextInt(threePrimes + 1);
        var b =
            -prando.nextInt(threePrimes + 1) + prando.nextInt(threePrimes + 1);
        var builder = BitBuilder();

        builder.writeInt(BigInt.from(a), bitLength + 1);
        builder.writeInt(BigInt.from(b), bitLength + 1);

        var bits = builder.build();

        {
          var reader = Cell(bits: bits).beginParse();
          expect(reader.preloadInt(bitLength + 1), a);
          expect(reader.loadInt(bitLength + 1), a);
          expect(reader.preloadInt(bitLength + 1), b);
          expect(reader.loadInt(bitLength + 1), b);
        }
        {
          var reader = Cell(bits: bits).beginParse();
          expect(reader.preloadIntBig(bitLength + 1).toInt(), a);
          expect(reader.loadIntBig(bitLength + 1).toInt(), a);
          expect(reader.preloadIntBig(bitLength + 1).toInt(), b);
          expect(reader.loadIntBig(bitLength + 1).toInt(), b);
        }
      }
    });

    test('Reading var uints from slice', () {
      var prando = Random('test-3'.codeUnits.sum);
      for (var i = 0; i < 1000; i += 1) {
        var sizeBits = prando.nextInt(4 + 1) + 4;
        var a = prando.nextInt(threePrimes + 1);
        var b = prando.nextInt(threePrimes + 1);
        var builder = BitBuilder();

        builder.writeVarUint(BigInt.from(a), sizeBits);
        builder.writeVarUint(BigInt.from(b), sizeBits);

        var bits = builder.build();

        {
          var reader = Cell(bits: bits).beginParse();
          expect(reader.preloadVarUint(sizeBits), a);
          expect(reader.loadVarUint(sizeBits), a);
          expect(reader.preloadVarUint(sizeBits), b);
          expect(reader.loadVarUint(sizeBits), b);
        }
        {
          var reader = Cell(bits: bits).beginParse();
          expect(reader.preloadVarUintBig(sizeBits).toInt(), a);
          expect(reader.loadVarUintBig(sizeBits).toInt(), a);
          expect(reader.preloadVarUintBig(sizeBits).toInt(), b);
          expect(reader.loadVarUintBig(sizeBits).toInt(), b);
        }
      }
    });

    test('Reading var ints from slice', () {
      var prando = Random('test-4'.codeUnits.sum);
      for (var i = 0; i < 1000; i += 1) {
        var sizeBits = prando.nextInt(4 + 1) + 4;
        var a =
            -prando.nextInt(threePrimes + 1) + prando.nextInt(threePrimes + 1);
        var b =
            -prando.nextInt(threePrimes + 1) + prando.nextInt(threePrimes + 1);
        var builder = BitBuilder();

        builder.writeVarInt(BigInt.from(a), sizeBits);
        builder.writeVarInt(BigInt.from(b), sizeBits);

        var bits = builder.build();

        {
          var reader = Cell(bits: bits).beginParse();
          expect(reader.preloadVarInt(sizeBits), a);
          expect(reader.loadVarInt(sizeBits), a);
          expect(reader.preloadVarInt(sizeBits), b);
          expect(reader.loadVarInt(sizeBits), b);
        }
        {
          var reader = Cell(bits: bits).beginParse();
          expect(reader.preloadVarIntBig(sizeBits).toInt(), a);
          expect(reader.loadVarIntBig(sizeBits).toInt(), a);
          expect(reader.preloadVarIntBig(sizeBits).toInt(), b);
          expect(reader.loadVarIntBig(sizeBits).toInt(), b);
        }
      }
    });

    test('Reading coins from slice', () {
      var prando = Random('test-5'.codeUnits.sum);
      for (var i = 0; i < 1000; i += 1) {
        var a = prando.nextInt(threePrimes + 1);
        var b = prando.nextInt(threePrimes + 1);
        var builder = BitBuilder();

        builder.writeCoins(BigInt.from(a));
        builder.writeCoins(BigInt.from(b));

        var bits = builder.build();
        var reader = Cell(bits: bits).beginParse();

        expect(reader.preloadCoins().toInt(), a);
        expect(reader.loadCoins().toInt(), a);
        expect(reader.preloadCoins().toInt(), b);
        expect(reader.loadCoins().toInt(), b);
      }
    });

    test('Reading internal addresses from slice', () {
      var prando = Random('test-6'.codeUnits.sum);
      for (var i = 0; i < 1000; i += 1) {
        var a = prando.nextInt(20) == 0
            ? createTestInternalAddress(-1, 'test-1$i')
            : null;
        var b = createTestInternalAddress(0, 'test-2$i');
        var builder = BitBuilder();

        builder.writeAddress(a);
        builder.writeAddress(b);

        var bits = builder.build();
        var reader = Cell(bits: bits).beginParse();

        if (a != null) {
          expect(
            reader.loadInternalAddressOrNull()!.toString(),
            a.toString(),
          );
        } else {
          expect(
            reader.loadInternalAddressOrNull(),
            null,
          );
        }

        expect(
          reader.loadInternalAddress().toString(),
          b.toString(),
        );
      }
    });
  });
}

createTestInternalAddress(int workchain, String seed) {
  final random = Random(seed.codeUnits.sum);
  final hash = Uint8List(32);

  for (var i = 0; i < hash.length; i += 1) {
    hash[i] = random.nextInt(256);
  }

  return InternalAddress(BigInt.from(workchain), hash);
}
