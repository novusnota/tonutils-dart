import '../cell/api.dart' show Builder, Slice;

// Source: https://github.com/ton-blockchain/ton/blob/24dc184a2ea67f9c47042b4104bbb4d82289fac1/crypto/block/block.tlb#L243
// acc_state_uninit$00 = AccountStatus;
// acc_state_frozen$01 = AccountStatus;
// acc_state_active$10 = AccountStatus;
// acc_state_nonexist$11 = AccountStatus;

/// Either of: AsUninitialized, AsFrozen, AsActive, AsNonExisting
sealed class AccountStatus {
  static const int uninitialized = 0x00;
  static const int frozen = 0x01;
  static const int active = 0x02;
  static const int nonExisting = 0x03;
}

/// Empty class, used as a type name
class AsUnitialized extends AccountStatus {}

/// Empty class, used as a type name
class AsFrozen extends AccountStatus {}

/// Empty class, used as a type name
class AsActive extends AccountStatus {}

/// Empty class, used as a type name
class AsNonExisting extends AccountStatus {}

/// Returns an AccountStatus from the Slice [slice]
///
/// Throws 'Invalid status' if the status value is not 0x00, 0x01, 0x02, or 0x03
AccountStatus loadAccountStatus(Slice slice) {
  final status = slice.loadUint(2);
  switch (status) {
    case AccountStatus.uninitialized:
      return AsUnitialized();

    case AccountStatus.frozen:
      return AsFrozen();

    case AccountStatus.active:
      return AsActive();

    case AccountStatus.nonExisting:
      return AsNonExisting();

    case _:
      throw 'Invalid status';
  }
}

/// Returns a Function from AccountStatus [src], which, when called, would store account status to builder and return back the builder
Builder Function(Builder builder) storeAccountStatus(AccountStatus src) {
  return (Builder builder) {
    switch (src) {
      case AsUnitialized():
        builder.storeUint(BigInt.from(AccountStatus.uninitialized), 2);

      case AsFrozen():
        builder.storeUint(BigInt.from(AccountStatus.frozen), 2);

      case AsActive():
        builder.storeUint(BigInt.from(AccountStatus.active), 2);

      case AsNonExisting():
        builder.storeUint(BigInt.from(AccountStatus.nonExisting), 2);
    }
    return builder;
  };
}
