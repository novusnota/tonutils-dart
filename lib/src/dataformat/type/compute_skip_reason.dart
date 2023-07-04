import '../cell/api.dart' show Builder, Slice;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L306
//  cskip_no_state$00 = ComputeSkipReason;
//  cskip_bad_state$01 = ComputeSkipReason;
//  cskip_no_gas$10 = ComputeSkipReason;

/// Either of: CsrNoState, CsrBadState, CsrNoGas
sealed class ComputeSkipReason {
  static const int noState = 0x00;
  static const int badState = 0x01;
  static const int noGas = 0x02;
}

/// Empty class, used as a type
class CsrNoState extends ComputeSkipReason {}

/// Empty class, used as a type
class CsrBadState extends ComputeSkipReason {}

/// Empty class, used as a type
class CsrNoGas extends ComputeSkipReason {}

/// Throws 'Unknown ComputeSkipReason...' if it's not one of: CsrNoState, CsrBadState, CsrNoGas
ComputeSkipReason loadComputeSkipReason(Slice slice) {
  var reason = slice.loadUint(2);
  switch (reason) {
    case ComputeSkipReason.noState:
      return CsrNoState();

    case ComputeSkipReason.badState:
      return CsrBadState();

    case ComputeSkipReason.noGas:
      return CsrNoGas();

    case _:
      throw 'Unknown ComputeSkipReason $reason';
  }
}

void Function(Builder builder) storeComputeSkipReason(ComputeSkipReason src) {
  return (Builder builder) {
    switch (src) {
      case CsrNoState():
        builder.storeUint(BigInt.from(ComputeSkipReason.noState), 2);

      case CsrBadState():
        builder.storeUint(BigInt.from(ComputeSkipReason.badState), 2);

      case CsrNoGas():
        builder.storeUint(BigInt.from(ComputeSkipReason.noGas), 2);
    }
  };
}
