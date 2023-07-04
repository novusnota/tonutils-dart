import '../../_utils/api.dart' show bitToBool, boolToBit;
import '../cell/api.dart' show Builder, Cell, Slice;
import '../dictionary/api.dart' show DictionaryValue;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L145
// simple_lib$_ public:Bool root:^Cell = SimpleLib;

/// (bool public, Cell root)
class SimpleLibrary {
  bool public;
  Cell root;

  SimpleLibrary(this.public, this.root);
}

SimpleLibrary loadSimpleLibrary(Slice slice) {
  var public = bitToBool(slice.loadBit());
  var root = slice.loadRef();

  return SimpleLibrary(public, root);
}

void Function(Builder builder) storeSimpleLibrary(SimpleLibrary src) {
  return (Builder builder) {
    builder.storeBit(boolToBit(src.public));
    builder.storeRef(src.root);
  };
}

// DictionaryValue<SimpleLibrary> createValueSimpleLibrary() {
//   return DictionaryValue(
//     serialize: (src, builder) {
//       storeSimpleLibrary(src)(builder);
//     },
//     parse: (src) {
//       return loadSimpleLibrary(src);
//     },
//   );
// }

final simpleLibraryValue = DictionaryValue(
  serialize: (src, builder) {
    storeSimpleLibrary(src)(builder);
  },
  parse: (src) {
    return loadSimpleLibrary(src);
  },
);
