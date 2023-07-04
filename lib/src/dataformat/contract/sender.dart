import '../address/api.dart' show InternalAddress;
import '../cell/api.dart' show Cell;
import '../type/send_mode.dart' show SendMode;
import 'api.dart' show ContractMaybeInit;

class SenderArguments {
  BigInt value;
  InternalAddress to;
  SendMode? sendMode;
  bool? bounce;
  ContractMaybeInit? init;
  Cell? body;

  SenderArguments({
    required this.value,
    required this.to,
    this.sendMode,
    this.bounce,
    this.init,
    this.body,
  });
}

class Sender {
  Future<void> Function(SenderArguments args) send;
  final InternalAddress? address;

  Sender({
    required this.send,
    this.address,
  });
}
