import '../address/api.dart' show InternalAddress;
import '../cell/api.dart' show Cell;
import 'api.dart' show ContractABI, ContractProvider;

/// ({Cell code, Cell data})
class ContractInit {
  Cell code;
  Cell data;

  ContractInit({
    required this.code,
    required this.data,
  });
}

/// ({Cell? code, Cell? data})
class ContractMaybeInit {
  Cell? code;
  Cell? data;

  ContractMaybeInit({
    this.code,
    this.data,
  });
}

/// ```dart
/// ContractProvider? provider;
/// late InternalAddress address;
/// ContractInit? init;
/// ContractABI? abi;
/// ```
abstract class Contract {
  ContractProvider? provider;
  late InternalAddress address;
  ContractInit? init;
  ContractABI? abi;
}

/// Returns a Contract with ContractProvider field set
T openContract<T extends Contract>(
  T src,
  ContractProvider Function({
    required InternalAddress address,
    ContractInit? init,
  }) factory,
) {
  InternalAddress address = src.address;
  ContractInit? init = src.init;

  var executor = factory(address: address, init: init);
  src.provider = executor;

  return src;
}
