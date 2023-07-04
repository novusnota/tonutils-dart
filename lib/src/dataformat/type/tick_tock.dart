import '../cell/api.dart' show Builder, Slice;
import '../../_utils/api.dart' show bitToBool;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L139
// tick_tock$_ tick:Bool tock:Bool = TickTock;

/// (bool tick, bool tock)
class TickTock {
  bool tick;
  bool tock;

  TickTock(this.tick, this.tock);
}

TickTock loadTickTock(Slice slice) {
  var tick = slice.loadBit();
  var tock = slice.loadBit();

  return TickTock(bitToBool(tick), bitToBool(tock));
}

void Function(Builder builder) storeTickTock(TickTock src) {
  return (Builder builder) {
    builder.storeBool(src.tick);
    builder.storeBool(src.tock);
  };
}
