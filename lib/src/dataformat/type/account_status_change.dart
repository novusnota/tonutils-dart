import '../cell/api.dart' show Builder, Slice;

// acst_unchanged$0 = AccStatusChange;  // x -> x
// acst_frozen$10 = AccStatusChange;    // init -> frozen
// acst_deleted$11 = AccStatusChange;   // frozen -> deleted

/// Either of: AscUnchanged, AscFrozen, AscDeleted
sealed class AccountStatusChange {}

/// Empty class, used as a type name
class AscUnchanged extends AccountStatusChange {}

/// Empty class, used as a type name
class AscFrozen extends AccountStatusChange {}

/// Empty class, used as a type name
class AscDeleted extends AccountStatusChange {}

AccountStatusChange loadAccountStatusChange(Slice slice) {
  if (slice.loadBool() == false) {
    return AscUnchanged();
  }
  if (slice.loadBool() == false) {
    // NOTE: consider swapping places
    return AscFrozen();
  }
  return AscDeleted();
}

void Function(Builder builder) storeAccountStatusChange(
    AccountStatusChange src) {
  return (Builder builder) {
    switch (src) {
      case AscUnchanged():
        builder.storeBit(0);

      case AscFrozen():
        builder.storeBit(1);
        builder.storeBit(0);

      case AscDeleted():
        builder.storeBit(1);
        builder.storeBit(1);
    }
  };
}
