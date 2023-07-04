import 'dart:typed_data';

/// ({BigInt lt, Uint8List hash})
class ContractStateLast {
  BigInt lt;
  Uint8List hash;

  ContractStateLast({
    required this.lt,
    required this.hash,
  });
}

/// Either CstUninit, CstActive or CstFrozen
sealed class ContractStateType {}

class CstUninit extends ContractStateType {}

class CstActive extends ContractStateType {
  Uint8List? code;
  Uint8List? data;

  CstActive({
    this.code,
    this.data,
  });
}

class CstFrozen extends ContractStateType {
  Uint8List stateHash;

  CstFrozen({
    required this.stateHash,
  });
}

class ContractState {
  BigInt balance;
  ContractStateLast? last;
  ContractStateType state;

  ContractState({
    required this.balance,
    required this.state,
    this.last,
  });
}
