import '../cell/api.dart' show Builder, Slice;
import '../dictionary/api.dart' show Dictionary, DktInt;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L120
// extra_currencies$_ dict:(HashmapE 32 (VarUInteger 32))
//  = ExtraCurrencyCollection;
//  currencies$_ grams:Grams other:ExtraCurrencyCollection
//            = CurrencyCollection;

class CurrencyCollection {
  BigInt coins;
  Dictionary<DktInt, BigInt>? other;

  CurrencyCollection(this.coins, [this.other]);
}

CurrencyCollection loadCurrencyCollection(Slice slice) {
  final coins = slice.loadCoins();
  final other = slice.loadDictionary(
    Dictionary.createKeyUint(32),
    Dictionary.createValueBigVarInt(5),
  );

  if (other.length == 0) {
    return CurrencyCollection(coins);
  }

  return CurrencyCollection(coins, other);
}

void Function(Builder builder) storeCurrencyCollection(
    CurrencyCollection collection) {
  return (Builder builder) {
    builder.storeCoins(collection.coins);

    if (collection.other != null) {
      builder.storeDictionary(collection.other);
    } else {
      builder.storeBit(0);
    }
  };
}
