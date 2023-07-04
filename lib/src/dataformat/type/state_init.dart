import '../cell/api.dart' show Builder, Cell, Slice;
import '../dictionary/api.dart' show Dictionary, DktBigInt;
import 'api.dart'
    show
        SimpleLibrary,
        simpleLibraryValue,
        loadTickTock,
        storeTickTock,
        TickTock;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L141
// _ split_depth:(Maybe (## 5)) special:(Maybe TickTock)
//  code:(Maybe ^Cell) data:(Maybe ^Cell)
//  library:(HashmapE 256 SimpleLib) = StateInit;

/// ```dart
/// ([int? splitDepth, TickTock? special, Cell? code, Cell? data, Dictionary<DktBigInt, SimpleLibrary>? libraries])
/// ```
class StateInit {
  int? splitDepth;
  TickTock? special;
  Cell? code;
  Cell? data;
  Dictionary<DktBigInt, SimpleLibrary>? libraries;

  StateInit([
    this.splitDepth,
    this.special,
    this.code,
    this.data,
    this.libraries,
  ]);
}

StateInit loadStateInit(Slice slice) {
  int? splitDepth;
  if (slice.loadBool()) {
    splitDepth = slice.loadUint(5);
  }

  TickTock? special;
  if (slice.loadBool()) {
    special = loadTickTock(slice);
  }

  var code = slice.loadMaybeRef();
  var data = slice.loadMaybeRef();

  var libraries = slice.loadDictionary(
    Dictionary.createKeyBigUint(256),
    simpleLibraryValue,
  );

  return StateInit(
    splitDepth,
    special,
    code,
    data,
    libraries.length == 0 ? null : libraries,
  );
}

void Function(Builder builder) storeStateInit(StateInit src) {
  return (Builder builder) {
    if (src.splitDepth != null) {
      builder.storeBit(1);
      builder.storeUint(BigInt.from(src.splitDepth!), 5);
    } else {
      builder.storeBit(0);
    }

    if (src.special != null) {
      builder.storeBit(1);
      builder.store(storeTickTock(src.special!));
    } else {
      builder.storeBit(0);
    }

    builder.storeMaybeRef(src.code);
    builder.storeMaybeRef(src.data);
    builder.storeDictionary(src.libraries);
  };
}
