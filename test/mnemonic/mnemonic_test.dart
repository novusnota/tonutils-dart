import 'package:convert/convert.dart';
import 'package:test/test.dart' show expect, group, test;
import 'package:tonutils/mnemonic.dart' show Mnemonic, WordList;

void main() {
  group('mnemonic/mnemonic', () {
    test('generate()', () {
      var mnemonic = Mnemonic.generate();

      expect(mnemonic.length, Mnemonic.wordsCount);
      expect(Mnemonic.isPasswordNeeded(mnemonic), false);
      expect(Mnemonic.isValid(mnemonic), true);
      expect(Mnemonic.isValid(mnemonic, 'arbitrary password'), false);
    });

    test('generate(password)', () {
      var randomIndex = Mnemonic.random.nextInt(WordList.bip39English.length);
      var randomWordAsPassword = WordList.bip39English[randomIndex];
      var mnemonic = Mnemonic.generate(randomWordAsPassword);

      expect(mnemonic.length, Mnemonic.wordsCount);
      expect(Mnemonic.isPasswordNeeded(mnemonic), true);
      expect(Mnemonic.isValid(mnemonic), false);
      expect(Mnemonic.isValid(mnemonic, randomWordAsPassword), true);
    });

    test('isValid()', () {
      expect(Mnemonic.isValid(_dummyMnemonic), true);
      expect(Mnemonic.isValid(_dummyPasswordMnemonic), false);
      expect(Mnemonic.isValid(_dummyPasswordMnemonic, 'arbitrary password'),
          false);
      expect(Mnemonic.isValid(_dummyPasswordMnemonic, _dummyPassword), true);
    });

    test('isPasswordNeeded()', () {
      expect(Mnemonic.isPasswordNeeded(_dummyMnemonic), false);
      expect(Mnemonic.isPasswordNeeded(_dummyPasswordMnemonic), true);
    });

    test('toSeed()', () {
      expect(hex.encode(Mnemonic.toSeed32(_dummyMnemonic)), _dummyBasicSeed);
    });

    test('toSeed(password)', () {
      expect(
          hex.encode(Mnemonic.toSeed32(_dummyPasswordMnemonic, _dummyPassword)),
          _dummyPasswordSeed);
    });

    test('toKeyPair()', () {
      var keyPair = Mnemonic.toKeyPair(_dummyMnemonic);

      // or .map((e) => {e.toRadixString(16)});
      expect(hex.encode(keyPair.publicKey), _dummyPublicKey);
      expect(hex.encode(keyPair.privateKey), _dummyPrivateKey);
    });

    test('toKeyPair(password)', () {
      var keyPair = Mnemonic.toKeyPair(_dummyPasswordMnemonic, _dummyPassword);

      expect(hex.encode(keyPair.publicKey), _dummyPasswordPublicKey);
      expect(hex.encode(keyPair.privateKey), _dummyPasswordPrivateKey);
    });
  });
}

const _dummyMnemonic = [
  'bring',
  'like',
  'escape',
  'health',
  'chimney',
  'pear',
  'whale',
  'peasant',
  'drum',
  'beach',
  'mass',
  'garden',
  'riot',
  'alien',
  'possible',
  'bus',
  'shove',
  'unable',
  'jar',
  'anxiety',
  'click',
  'salon',
  'canoe',
  'lion',
];

const _dummyPasswordMnemonic = [
  'minimum',
  'candy',
  'praise',
  'dolphin',
  'doll',
  'arrest',
  'duty',
  'pill',
  'bronze',
  'embrace',
  'execute',
  'midnight',
  'trial',
  'pink',
  'guitar',
  'cake',
  'sail',
  'color',
  'field',
  'used',
  'art',
  'method',
  'fashion',
  'supply',
];

const _dummyPassword = 'foobar';

const _dummyBasicSeed =
    '5844f115d314ff833331ee02bbfea358b5a0c1521c65e70f8c29cbde9f38b5c3';

const _dummyPasswordSeed =
    '2299becdd2c577f38f5c3ceda4577920968c8e41571e64547c018a64edc2131e';

const _dummyPublicKey =
    'ef117f300d4eca0f88ffd17d00340dee0c864b0d8300197203143c036af3be29';
const _dummyPrivateKey =
    '5844f115d314ff833331ee02bbfea358b5a0c1521c65e70f8c29cbde9f38b5c3ef117f300d4eca0f88ffd17d00340dee0c864b0d8300197203143c036af3be29';

const _dummyPasswordPublicKey =
    '2906a33e8edb1ee2a0b9974a817113914b4996796f2af12b7c20712a974e9638';
const _dummyPasswordPrivateKey =
    '2299becdd2c577f38f5c3ceda4577920968c8e41571e64547c018a64edc2131e2906a33e8edb1ee2a0b9974a817113914b4996796f2af12b7c20712a974e9638';
