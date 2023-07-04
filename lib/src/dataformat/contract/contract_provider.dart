import '../cell/api.dart' show Cell;
import '../tuple/api.dart' show TupleReader, TupleItem;
import '../type/api.dart' show SendMode, StringBigInt, StringCell;
import 'api.dart' show ContractState, Sender;

/// ```dart
/// ({
///   TupleReader stack,
///   BigInt? gasUsed,
///   String? logs,
/// })
/// ```
class ContractGetMethodResult {
  TupleReader stack;
  BigInt? gasUsed;
  String? logs;

  ContractGetMethodResult({
    required this.stack,
    this.gasUsed,
    this.logs,
  });
}

/// ```dart
/// (Future<ContractState> Function() getState,
///  Future<ContractGetMethodResult> Function(String name, List<TupleItem> args) get,
///  Future<void> Function(Cell message) external,
///  Future<void> Function(
///    Sender via, {
///    required StringBigInt value,
///    bool? bounce,
///    SendMode? sendMode,
///    StringCell? body,
///  }) internal)
/// ```
class ContractProvider {
  Future<ContractState> Function() getState;
  Future<ContractGetMethodResult> Function(String name, List<TupleItem> args)
      get;
  Future<void> Function(Cell message) external;
  Future<void> Function(
    Sender via, {
    required StringBigInt value,
    bool? bounce,
    SendMode? sendMode,
    StringCell? body,
  }) internal;

  ContractProvider(this.getState, this.get, this.external, this.internal);
}
