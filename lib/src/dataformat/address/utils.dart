import 'api.dart' show InternalAddress;
import '../cell/api.dart' show beginCell;
import '../type/api.dart' show StateInit, storeStateInit;

InternalAddress address(String src) {
  return InternalAddress.parse(src);
}

InternalAddress contractAddress(int workChain, StateInit init) {
  var hash = beginCell().store(storeStateInit(init)).endCell().hash();

  return InternalAddress(BigInt.from(workChain), hash);
}
