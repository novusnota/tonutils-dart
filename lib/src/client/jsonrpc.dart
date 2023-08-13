import 'dart:convert';
import 'dart:typed_data';
import 'package:collection/collection.dart';
import 'package:convert/convert.dart';
import 'package:http/http.dart' as http;

import '../dataformat/address/api.dart' show InternalAddress;
import '../dataformat/cell/api.dart' show beginCell, Cell;
import '../dataformat/contract/api.dart'
    show
        Contract,
        ContractGetMethodResult,
        ContractInit,
        ContractMaybeInit,
        ContractProvider,
        ContractState,
        ContractStateLast,
        ContractStateType,
        CstActive,
        CstFrozen,
        CstUninit,
        SenderArguments,
        openContract;
import '../dataformat/nano/api.dart' show Nano;
import '../dataformat/tuple/api.dart'
    show
        TiBuilder,
        TiCell,
        TiInt,
        TiNan,
        TiNull,
        TiSlice,
        TiTuple,
        TupleItem,
        TupleReader;
import '../dataformat/type/api.dart'
    show
        Message,
        SbiBigInt,
        SbiString,
        ScCell,
        ScString,
        SendMode,
        SiaInternalAddress,
        StringBigInt,
        StringCell,
        Transaction,
        comment,
        external,
        loadTransaction,
        storeMessage;

/// TON Blockchain client over jsonRPC
class TonJsonRpc {
  /// API endpoint
  final String endpoint;

  /// API key
  final String? apiKey;

  /// HTTP request timeout in milliseconds
  final int timeout;

  /// Expects an [endpoint] as either of:
  /// - 'https://testnet.toncenter.com/api/v2/jsonRPC'
  /// - 'https://toncenter.com/api/v2/jsonRPC'
  /// - your own instance of TON HTTP API,
  ///   see more here: https://github.com/toncenter/ton-http-api
  TonJsonRpc([
    this.endpoint = 'https://testnet.toncenter.com/api/v2/jsonRPC',
    this.apiKey,
    this.timeout = 30000,
  ]);

  /// Returns the address balance as a Future<BigInt>
  Future<BigInt> getBalance(InternalAddress address) async {
    return (await getContractState(address)).balance;
  }

  /// Returns the gas used and the stack after the get method invocation as a record, wrapped in a Future:
  /// ```dart
  /// Future<({
  ///   int gasUsed,
  ///   TupleReader stack,
  /// })>
  /// ```
  ///
  /// Throws 'Unable to execute...' if the exit code != 0
  Future<({int gasUsed, TupleReader stack})> runMethod(
    InternalAddress address,
    String methodName, [
    List<TupleItem> stack = const <TupleItem>[],
  ]) async {
    var res = await _callGetMethod(address, methodName, stack);
    if (res.exitCode != 0) {
      throw 'Unable to execute get method, got exit code ${res.exitCode}';
    }
    return (
      gasUsed: res.gasUsed,
      stack: _deserializeStack(res.stack),
    );
  }

  /// Returns the gas used, stack and the exit code after the get method invocation as a record, wrapped in a Future:
  /// ```dart
  /// Future<({
  ///   int gasUsed,
  ///   TupleReader stack,
  ///   int exitCode
  /// })>
  /// ```
  Future<({int gasUsed, TupleReader stack, int exitCode})> runMethodWithError(
    InternalAddress address,
    String methodName,
    List<TupleItem> stack,
  ) async {
    var res = await _callGetMethod(address, methodName, stack);

    return (
      gasUsed: res.gasUsed,
      stack: _deserializeStack(res.stack),
      exitCode: res.exitCode,
    );
  }

  /// Returns a List<Transaction> wrapped in a Future
  Future<List<Transaction>> getTransactions(
    InternalAddress address, {
    required int limit,
    String? lt,
    String? hash,
    String? toLt,
    bool? inclusive,
  }) async {
    var tx = await _getTransactions(
      address,
      limit: limit,
      lt: lt,
      hash: hash,
      toLt: toLt,
      inclusive: inclusive,
    );
    var res = <Transaction>[];
    for (var i = 0; i < tx.transactions.length; i += 1) {
      var boc = base64.decode(tx.transactions[i].data);
      res.add(loadTransaction(Cell.fromBoc(boc)[0].beginParse()));
    }

    return res;
  }

  /// Returns a transaction by its logical time [lt] and a base64 encoded [hash] as a Transaction? wrapped in a Future
  Future<Transaction?> getTransaction(
    InternalAddress address,
    String lt,
    String hash,
  ) async {
    var res = await _getTransaction(address, lt, hash);
    if (res != null) {
      var boc = base64.decode(res.data);
      return loadTransaction(Cell.fromBoc(boc)[0].beginParse());
    }
    return null;
  }

  /// Returns the latest masterchain info as a record, wrapped in a Future:
  /// ```dart
  /// Future<({
  ///   int initSeqno,
  ///   int latestSeqno,
  ///   String shard,
  ///   int workchain,
  /// })>
  /// ```
  Future<
      ({
        int initSeqno,
        int latestSeqno,
        String shard,
        int workchain,
      })> getMasterchainInfo() async {
    var res = await _getMasterchainInfo();

    return (
      workchain: res.init.workchain,
      shard: res.last.shard,
      initSeqno: res.init.seqno,
      latestSeqno: res.last.seqno,
    );
  }

  /// Returns the latest workchain shards as a List of records, wrapped in a Future:
  /// ```dart
  /// Future<List<({
  ///   int workchain,
  ///   String shard,
  ///   int seqno,
  /// })>>
  /// ```
  Future<
      List<
          ({
            int workchain,
            String shard,
            int seqno,
          })>> getWorkchainShards(int seqno) async {
    var shards = (await _getShards(seqno)).shards;
    var res = <({int workchain, String shard, int seqno})>[];

    for (var i = 0; i < shards.length; i += 1) {
      res.add((
        workchain: shards[i].workchain,
        shard: shards[i].shard,
        seqno: shards[i].seqno,
      ));
    }

    return res;
  }

  /// Returns the latest workchain shards as a List of records, wrapped in a Future:
  /// ```dart
  /// Future<List<({
  ///   InternalAddress account,
  ///   LastTransactionId lastTransactionId,
  /// })>>
  /// ```
  ///
  /// Throws 'Unsupported' if the incomplete flag is true
  Future<
      List<
          ({
            InternalAddress account,
            LastTransactionId lastTransactionId,
          })>> getShardTransactions(
      int workchain, int seqno, String shard) async {
    var tx = await _getBlockTransactions(workchain, seqno, shard);
    if (tx.incomplete == true) {
      throw 'Unsupported';
    }
    var res = <({
      InternalAddress account,
      LastTransactionId lastTransactionId,
    })>[];

    for (var i = 0; i < tx.transactions.length; i += 1) {
      res.add((
        account: InternalAddress.parseRaw(tx.transactions[i].account),
        lastTransactionId: LastTransactionId(
          lt: tx.transactions[i].lt,
          hash: tx.transactions[i].hash,
        ),
      ));
    }

    return res;
  }

  /// Returns nothing, sends a message [src] as a BoC to the network
  Future<void> sendMessage(Message src) async {
    final boc = beginCell().store(storeMessage(src)).endCell().toBoc();
    await _sendBoc(boc);
  }

  /// Returns nothing, sends a BoC file [src] directly to the network
  Future<void> sendFile(Uint8List src) async {
    await _sendBoc(src);
  }

  /// Returns a fee estimate for the external message as a record, wrapped in a Future:
  /// ```dart
  /// Future<({
  ///   int inForwardFee,
  ///   int storageFee,
  ///   int gasFee,
  ///   int forwardFee,
  /// })>
  /// ```
  Future<
      ({
        int forwardFee,
        int gasFee,
        int inForwardFee,
        int storageFee,
      })> estimateExternalMessageFee(
    InternalAddress address, {
    required Cell body,
    Cell? initCode,
    Cell? initData,
    required bool ignoreSignature,
  }) async {
    var fees = await _estimateFee(
      address,
      body: body,
      initCode: initCode,
      initData: initData,
      ignoreSignature: ignoreSignature,
    );

    return (
      inForwardFee: fees.sourceFees.inForwardFee,
      storageFee: fees.sourceFees.storageFee,
      gasFee: fees.sourceFees.gasFee,
      forwardFee: fees.sourceFees.forwardFee,
    );
  }

  /// Returns nothing, sends an external message to contract
  sendExternalMessage(Contract contract, Cell src) async {
    var isDeployed = await isContractDeployed(contract.address);

    if (isDeployed) {
      final message = external(
        to: SiaInternalAddress(contract.address),
        body: src,
      );
      await sendMessage(message);
      return;
    }

    final message = external(
      to: SiaInternalAddress(contract.address),
      init: ContractMaybeInit(
        code: contract.init?.code,
        data: contract.init?.data,
      ),
      body: src,
    );
    await sendMessage(message);
  }

  /// Returns a bool, wrapped in a Future: true if contract is in active state, false otherwise
  Future<bool> isContractDeployed(InternalAddress address) async {
    return (await getContractState(address)).state == 'active';
  }

  /// Returns a contract state as a record, wrapped in a Future:
  /// ```dart
  /// Future<({
  ///   BigInt balance,
  ///   String state,
  ///   Uint8List? code,
  ///   Uint8List? data,
  ///   LastTransactionId? lastTransaction,
  ///   ({int seqno, String shard, int workchain}) blockId,
  ///   int timestamp
  /// })>
  /// ```
  Future<
      ({
        BigInt balance,
        String state,
        Uint8List? code,
        Uint8List? data,
        LastTransactionId? lastTransaction,
        ({int seqno, String shard, int workchain}) blockId,
        int timestamp
      })> getContractState(InternalAddress address) async {
    var info = await _getAddressInformation(address);

    BigInt balance = switch (info.balance) {
      SbiString() => BigInt.parse((info.balance as SbiString).value),
      SbiBigInt() => (info.balance as SbiBigInt).value,
    };

    var state = info.state;

    return (
      balance: balance,
      state: state,
      code:
          info.code != '' ? Uint8List.fromList(base64.decode(info.code)) : null,
      data:
          info.data != '' ? Uint8List.fromList(base64.decode(info.data)) : null,
      lastTransaction: info.lastTransactionId.lt != '0'
          ? LastTransactionId(
              lt: info.lastTransactionId.lt,
              hash: info.lastTransactionId.hash,
            )
          : null,
      blockId: (
        workchain: info.blockId.workchain,
        shard: info.blockId.shard,
        seqno: info.blockId.seqno
      ),
      timestamp: info.syncUtime,
    );
  }

  /// Returns a new opened contract with the ContractProvider initialized
  T open<T extends Contract>(T src) {
    return openContract<T>(
        src,
        ({required InternalAddress address, ContractInit? init}) =>
            _createProvider(
                this,
                address,
                init != null
                    ? ContractMaybeInit(
                        code: init.code,
                        data: init.data,
                      )
                    : null));
  }

  /// Returns a new ContractProvider
  ContractProvider provider(InternalAddress address, ContractMaybeInit? init) {
    return _createProvider(this, address, init);
  }

  ContractProvider _createProvider(
    TonJsonRpc client,
    InternalAddress address,
    ContractMaybeInit? init,
  ) {
    return ContractProvider(
      // getState
      () async {
        var state = await client.getContractState(address);
        var balance = state.balance;
        var last = state.lastTransaction != null
            ? ContractStateLast(
                lt: BigInt.parse(state.lastTransaction!.lt),
                hash: Uint8List.fromList(
                    base64.decode(state.lastTransaction!.hash)),
              )
            : null;
        ContractStateType storage;
        switch (state.state) {
          case 'active':
            storage = CstActive(
              code: state.code,
              data: state.data,
            );

          case 'uninitialized':
            storage = CstUninit();

          case 'frozen':
            storage = CstFrozen(stateHash: Uint8List(0));

          case _:
            throw 'Unsupported state ${state.state}';
        }

        return ContractState(
          balance: balance,
          last: last,
          state: storage,
        );
      },
      // get
      (name, args) async {
        var method = await client.runMethod(address, name, args);
        return ContractGetMethodResult(
          stack: method.stack,
          gasUsed: BigInt.from(method.gasUsed),
        );
      },
      // external
      (message) async {
        // Resolve init
        ContractMaybeInit? neededInit;
        if (init != null &&
            (await client.isContractDeployed(address)) == false) {
          neededInit = init;
        }

        // Send
        final ext = external(
          to: SiaInternalAddress(address),
          init: neededInit,
          body: message,
        );
        var boc = beginCell().store(storeMessage(ext)).endCell().toBoc();
        await client.sendFile(boc);
      },
      // internal
      (
        via, {
        required StringBigInt value,
        StringCell? body,
        bool? bounce,
        SendMode? sendMode,
      }) async {
        // Resolve init
        ContractMaybeInit? neededInit;
        if (init != null &&
            (await client.isContractDeployed(address)) == false) {
          neededInit = init;
        }

        // Resolve bounce
        var lBounce = true;
        if (bounce != null) {
          lBounce = bounce;
        }

        // Resolve value
        BigInt lValue;
        switch (value) {
          case SbiString():
            lValue = Nano.fromString(value.value);

          case SbiBigInt():
            lValue = value.value;
        }

        // Resolve body
        Cell? lBody;
        switch (body) {
          case ScString():
            lBody = comment(body.value);

          case ScCell():
            lBody = body.value;

          case null:
            break;
        }

        // Send internal message
        await via.send(SenderArguments(
          to: address,
          value: lValue,
          bounce: lBounce,
          sendMode: sendMode,
          init: neededInit,
          body: lBody,
        ));
      },
    );
  }

  // NOTE: consider making those functions into separate utils?
  static List<List<String>> _serializeStack(List<TupleItem> src) {
    var stack = <List<String>>[];
    for (var i = 0; i < src.length; i += 1) {
      var item = src[i];
      switch (item) {
        case TiInt():
          stack.add(<String>['num', item.value.toString()]);

        case TiCell():
          stack.add(<String>['tvm.Cell', base64.encode(item.cell.toBoc())]);

        case TiSlice():
          stack.add(<String>['tvm.Slice', base64.encode(item.cell.toBoc())]);

        case TiBuilder():
          stack.add(<String>['tvm.Builder', base64.encode(item.cell.toBoc())]);

        case TiTuple():
        case TiNan():
        case TiNull():
          throw 'Unsupported stack item type: ${item.runtimeType}';
      }
    }
    return stack;
  }

  static TupleReader _deserializeStack(List<List<String>> src) {
    var stack = <TupleItem>[];
    for (var i = 0; i < src.length; i += 1) {
      switch (src[i][0]) {
        case 'num':
          var v = src[i][1];
          if (v.startsWith('-')) {
            stack.add(TiInt(
              -BigInt.parse(v.substring(1)),
            ));
          } else {
            stack.add(TiInt(
              BigInt.parse(v),
            ));
          }

        case 'null':
          stack.add(TiNull());

        case 'cell':
          stack.add(TiCell(Cell.fromBocBase64(src[i][1])));

        case 'slice':
          stack.add(TiSlice(Cell.fromBocBase64(src[i][1])));

        case 'builder':
          stack.add(TiBuilder(Cell.fromBocBase64(src[i][1])));

        case _:
          throw 'Unsupported stack item type ${src[i][0]}';
      }
    }
    return TupleReader(stack);
  }

  dynamic _call(String method, Map<String, dynamic> body) async {
    var headers = <String, String>{
      'Content-Type': 'application/json; charset=UTF-8',
    };
    if (apiKey != null) {
      headers['X-API-Key'] = apiKey!;
    }

    var uri = Uri.parse(endpoint);
    var response = await http.post(
      uri,
      headers: headers,
      body: jsonEncode(<String, dynamic>{
        'id': '1',
        'jsonrpc': '2.0',
        'method': method,
        'params': body,
      }),
    );
    switch (response.statusCode) {
      case 504:
        throw 'Lite Server Timeout, ${response.reasonPhrase}';
      case 422:
        throw 'Validation Error on Lite Server, ${response.reasonPhrase}';
      case _:
        break;
    }

    var decoded = jsonDecode(response.body);

    if (decoded['ok'] == false) {
      // ignore: prefer_interpolation_to_compose_strings
      throw 'Received an error: ' + decoded['error'];
    }

    return decoded['result'];
  }

  Future<RpcCallGetMethod> _callGetMethod(
    InternalAddress address,
    String method,
    List<TupleItem> stack,
  ) async {
    var res = await _call('runGetMethod', <String, dynamic>{
      'address': address.toString(),
      'method': method,
      'stack': _serializeStack(stack),
    });
    return _parseCallGetMethod(res);
  }

  Future<RpcGetTransaction?> _getTransaction(
    InternalAddress address,
    String lt,
    String hash,
  ) async {
    var convHash = hex.encode(base64.decode(hash));
    var res = await _call('getTransactions', <String, dynamic>{
      'address': address.toString(),
      'lt': lt,
      'hash': convHash,
      'limit': 1,
    });
    var parsed = _parseGetTransactions(res);

    String convToFriendly(String src) =>
        src.replaceAll(RegExp(r'\-'), '+').replaceAll(RegExp(r'_'), '/');

    var ex = parsed.transactions.firstWhereOrNull((v) {
      return v.transactionId.lt == lt &&
          v.transactionId.hash == convToFriendly(hash);
    });

    return ex;
  }

  Future<RpcGetTransactions> _getTransactions(
    InternalAddress address, {
    required int limit,
    String? lt,
    String? hash,
    String? toLt,
    bool? inclusive,
  }) async {
    // Convert hash
    String? lHash;
    if (hash != null) {
      lHash = hex.encode(base64.decode(hash));
    }

    // Adjust limit
    var lLimit = limit;
    if (hash != null && lt != null && inclusive != true) {
      lLimit += 1;
    }

    // Do request
    var body = <String, dynamic>{
      'address': address.toString(),
      'limit': lLimit,
      'hash': lHash,
    };
    if (lt != null) {
      body['lt'] = lt;
    }
    if (toLt != null) {
      body['to_lt'] = toLt;
    }
    var res = await _call('getTransactions', body);
    var parsed = _parseGetTransactions(res);
    if (parsed.transactions.length > lLimit) {
      parsed.transactions = parsed.transactions.sublist(0, limit);
    }

    // Adjust result
    if (hash != null && lt != null && inclusive != null && inclusive != true) {
      parsed.transactions.removeAt(0);
    }

    return parsed;
  }

  Future<RpcAddressInformation> _getAddressInformation(
    InternalAddress address,
  ) async {
    var res = await _call('getAddressInformation', <String, dynamic>{
      'address': address.toString(),
    });
    var parsed = _parseAddressInformation(res);

    return parsed;
  }

  Future<RpcMasterchainInfo> _getMasterchainInfo() async {
    var res = await _call('getMasterchainInfo', <String, dynamic>{});
    var parsed = _parseMasterchainInfo(res);

    return parsed;
  }

  Future<void> _sendBoc(Uint8List body) async {
    await _call('sendBoc', <String, dynamic>{
      'boc': base64.encode(body),
    });
  }

  Future<RpcEstimateFee> _estimateFee(
    InternalAddress address, {
    required Cell body,
    Cell? initCode,
    Cell? initData,
    required bool ignoreSignature,
  }) async {
    var res = await _call('estimateFee', <String, dynamic>{
      'address': address.toString(),
      'body': base64.encode(body.toBoc()),
      'init_data': initData != null ? base64.encode(initData.toBoc()) : '',
      'init_code': initCode != null ? base64.encode(initCode.toBoc()) : '',
      'ignore_chksig': ignoreSignature,
    });
    var parsed = _parseEstimateFee(res);

    return parsed;
  }

  Future<RpcGetShards> _getShards(int seqno) async {
    var res = await _call('shards', <String, dynamic>{
      'seqno': seqno,
    });
    var parsed = _parseGetShards(res);

    return parsed;
  }

  Future<RpcBlockTransactions> _getBlockTransactions(
    int workchain,
    int seqno,
    String shard,
  ) async {
    var res = await _call('getBlockTransactions', <String, dynamic>{
      'workchain': workchain,
      'seqno': seqno,
      'shard': shard,
    });
    var parsed = _parseGetBlockTransactions(res);

    return parsed;
  }
}

//
// Types
//

sealed class RpcResponse {}

//

class RpcBlockShortTxt {
  int mode;
  String account;
  String lt;
  String hash;

  RpcBlockShortTxt({
    required this.mode,
    required this.account,
    required this.lt,
    required this.hash,
  });
}

class RpcBlockTransactions extends RpcResponse {
  RpcBlockIdExt id;
  int reqCount;
  bool incomplete;
  List<RpcBlockShortTxt> transactions;

  RpcBlockTransactions({
    required this.id,
    required this.reqCount,
    required this.incomplete,
    required this.transactions,
  });
}

RpcBlockTransactions _parseGetBlockTransactions(dynamic responseData) {
  var id = RpcBlockIdExt(
    workchain: responseData['id']['workchain'] as int,
    shard: responseData['id']['shard'] as String,
    seqno: responseData['id']['seqno'] as int,
    rootHash: responseData['id']['root_hash'] as String,
    fileHash: responseData['id']['file_hash'] as String,
  );
  var reqCount = responseData['req_count'] as int;
  var incomplete = responseData['incomplete'] as bool;

  var rawTransactions = responseData['transactions'] as List<dynamic>;
  var transactions = <RpcBlockShortTxt>[];
  for (var i = 0; i < rawTransactions.length; i += 1) {
    transactions.add(RpcBlockShortTxt(
      mode: rawTransactions[i]['mode'] as int,
      account: rawTransactions[i]['account'] as String,
      lt: rawTransactions[i]['lt'] as String,
      hash: rawTransactions[i]['hash'] as String,
    ));
  }

  return RpcBlockTransactions(
    id: id,
    reqCount: reqCount,
    incomplete: incomplete,
    transactions: transactions,
  );
}

//

class RpcGetShards extends RpcResponse {
  List<RpcBlockIdExt> shards;

  RpcGetShards({
    required this.shards,
  });
}

RpcGetShards _parseGetShards(dynamic responseData) {
  var rawShards = responseData['shards'] as List<dynamic>;
  var shards = <RpcBlockIdExt>[];
  for (var i = 0; i < rawShards.length; i += 1) {
    shards.add(RpcBlockIdExt(
      workchain: rawShards[i]['workchain'] as int,
      shard: rawShards[i]['shard'] as String,
      seqno: rawShards[i]['seqno'] as int,
      rootHash: rawShards[i]['root_hash'] as String,
      fileHash: rawShards[i]['file_hash'] as String,
    ));
  }

  return RpcGetShards(shards: shards);
}

//

class RpcSourceFee {
  int inForwardFee;
  int storageFee;
  int gasFee;
  int forwardFee;

  RpcSourceFee({
    required this.inForwardFee,
    required this.storageFee,
    required this.gasFee,
    required this.forwardFee,
  });
}

class RpcEstimateFee extends RpcResponse {
  RpcSourceFee sourceFees;

  RpcEstimateFee({
    required this.sourceFees,
  });
}

RpcEstimateFee _parseEstimateFee(dynamic responseData) {
  var sourceFee = RpcSourceFee(
    inForwardFee: responseData['source_fees']['in_fwd_fee'] as int,
    storageFee: responseData['source_fees']['storage_fee'] as int,
    gasFee: responseData['source_fees']['gas_fee'] as int,
    forwardFee: responseData['source_fees']['fwd_fee'] as int,
  );
  return RpcEstimateFee(sourceFees: sourceFee);
}

class RpcMasterchainInfo extends RpcResponse {
  String stateRootHash;
  RpcBlockIdExt last;
  RpcBlockIdExt init;

  RpcMasterchainInfo({
    required this.stateRootHash,
    required this.last,
    required this.init,
  });
}

RpcMasterchainInfo _parseMasterchainInfo(dynamic responseData) {
  var stateRootHash = responseData['state_root_hash'] as String;
  var last = RpcBlockIdExt(
    workchain: responseData['last']['workchain'] as int,
    shard: responseData['last']['shard'] as String,
    seqno: responseData['last']['seqno'] as int,
    rootHash: responseData['last']['root_hash'] as String,
    fileHash: responseData['last']['file_hash'] as String,
  );
  var init = RpcBlockIdExt(
    workchain: responseData['init']['workchain'] as int,
    shard: responseData['init']['shard'] as String,
    seqno: responseData['init']['seqno'] as int,
    rootHash: responseData['init']['root_hash'] as String,
    fileHash: responseData['init']['file_hash'] as String,
  );

  return RpcMasterchainInfo(
    stateRootHash: stateRootHash,
    last: last,
    init: init,
  );
}

//

class RpcBlockIdExt extends RpcResponse {
  int workchain;
  String shard;
  int seqno;
  String rootHash;
  String fileHash;

  RpcBlockIdExt({
    required this.workchain,
    required this.shard,
    required this.seqno,
    required this.rootHash,
    required this.fileHash,
  });
}

/// ```dart
/// ({
///   String lt,
///   String hash,
/// })
/// ```
class LastTransactionId {
  String lt;
  String hash;

  LastTransactionId({
    required this.lt,
    required this.hash,
  });
}

class RpcAddressInformation extends RpcResponse {
  StringBigInt balance;
  String state;
  String data;
  String code;
  LastTransactionId lastTransactionId;
  RpcBlockIdExt blockId;
  int syncUtime;

  RpcAddressInformation({
    required this.balance,
    required this.state,
    required this.data,
    required this.code,
    required this.lastTransactionId,
    required this.blockId,
    required this.syncUtime,
  });
}

RpcAddressInformation _parseAddressInformation(dynamic responseData) {
  StringBigInt balance;
  switch (responseData['balance'].runtimeType) {
    case String:
      balance = SbiString(responseData['balance'] as String);

    case int:
      balance = SbiBigInt(BigInt.from(responseData['balance'] as int));

    case BigInt:
      balance = SbiBigInt(responseData['balance'] as BigInt);

    case _:
      throw 'Unexpected type of the balance: ${responseData['balance'].runtimeType}';
  }
  var state = responseData['state'] as String;
  var data = responseData['data'] as String;
  var code = responseData['code'] as String;
  var lastTransactionId = LastTransactionId(
    lt: responseData['last_transaction_id']['lt'] as String,
    hash: responseData['last_transaction_id']['hash'] as String,
  );
  var blockId = RpcBlockIdExt(
    workchain: responseData['block_id']['workchain'] as int,
    shard: responseData['block_id']['shard'] as String,
    seqno: responseData['block_id']['seqno'] as int,
    rootHash: responseData['block_id']['root_hash'] as String,
    fileHash: responseData['block_id']['file_hash'] as String,
  );
  var syncUtime = responseData['sync_utime'] as int;

  return RpcAddressInformation(
    balance: balance,
    state: state,
    data: data,
    code: code,
    lastTransactionId: lastTransactionId,
    blockId: blockId,
    syncUtime: syncUtime,
  );
}

//

class RpcGetTransactions extends RpcResponse {
  List<RpcGetTransaction> transactions;

  RpcGetTransactions({
    required this.transactions,
  });
}

RpcGetTransactions _parseGetTransactions(dynamic responseData) {
  var list = responseData as List<dynamic>;
  var transactions = <RpcGetTransaction>[];

  for (var i = 0; i < list.length; i += 1) {
    transactions.add(_parseGetTransaction(list[i]));
  }

  return RpcGetTransactions(transactions: transactions);
}

//

sealed class RpcMessageData {}

class RmdRaw extends RpcMessageData {
  String body;

  RmdRaw({
    required this.body,
  });
}

class RmdText extends RpcMessageData {
  String text;

  RmdText({
    required this.text,
  });
}

class RmdDecryptedText extends RpcMessageData {
  String text;

  RmdDecryptedText({
    required this.text,
  });
}

class RmdEncryptedText extends RpcMessageData {
  String text;

  RmdEncryptedText({
    required this.text,
  });
}

class RpcMessage {
  String source;
  String destination;
  String value;
  String forwardFee;
  String ihrFee;
  String createdLt;
  String bodyHash;
  RpcMessageData msgData;

  RpcMessage({
    required this.source,
    required this.destination,
    required this.value,
    required this.forwardFee,
    required this.ihrFee,
    required this.createdLt,
    required this.bodyHash,
    required this.msgData,
  });
}

class RpcTransactionId {
  String lt;
  String hash;

  RpcTransactionId({
    required this.lt,
    required this.hash,
  });
}

class RpcGetTransaction extends RpcResponse {
  String data;
  int utime;
  RpcTransactionId transactionId;
  String fee;
  String storageFee;
  String otherFee;
  RpcMessage? inMsg;
  List<RpcMessage> outMsgs;

  RpcGetTransaction({
    required this.data,
    required this.utime,
    required this.transactionId,
    required this.fee,
    required this.storageFee,
    required this.otherFee,
    this.inMsg,
    required this.outMsgs,
  });
}

RpcMessage _parseRpcMessage(dynamic responseData) {
  var source = responseData['source'] as String;
  var destination = responseData['destination'] as String;
  var value = responseData['value'] as String;
  var forwardFee = responseData['fwd_fee'] as String;
  var ihrFee = responseData['ihr_fee'] as String;
  var createdLt = responseData['created_lt'] as String;
  var bodyHash = responseData['body_hash'] as String;
  RpcMessageData msgData;

  switch (responseData['msg_data']['@type']) {
    case 'msg.dataRaw':
      msgData = RmdRaw(body: responseData['msg_data']['body'] as String);

    case 'msg.dataText':
      msgData = RmdText(text: responseData['msg_data']['text'] as String);

    case 'msg.dataDecryptedText':
      msgData =
          RmdDecryptedText(text: responseData['msg_data']['text'] as String);

    case 'msg.dataEncryptedText':
      msgData =
          RmdEncryptedText(text: responseData['msg_data']['text'] as String);

    case _:
      throw 'Unsupported @type of the message: ${responseData["@type"]}';
  }

  return RpcMessage(
    source: source,
    destination: destination,
    value: value,
    forwardFee: forwardFee,
    ihrFee: ihrFee,
    createdLt: createdLt,
    bodyHash: bodyHash,
    msgData: msgData,
  );
}

RpcGetTransaction _parseGetTransaction(dynamic responseData) {
  var data = responseData['data'] as String;
  var utime = responseData['utime'] as int;
  var transactionId = RpcTransactionId(
    lt: responseData['transaction_id']['lt'] as String,
    hash: responseData['transaction_id']['hash'] as String,
  );
  var fee = responseData['fee'] as String;
  var storageFee = responseData['storage_fee'] as String;
  var otherFee = responseData['other_fee'] as String;

  var inMsg = responseData['in_msg'] != null
      ? _parseRpcMessage(responseData['in_msg'])
      : null;

  var rawMsgs = responseData['out_msgs'] as List<dynamic>;
  var outMsgs = <RpcMessage>[];

  for (var i = 0; i < rawMsgs.length; i += 1) {
    outMsgs.add(_parseRpcMessage(rawMsgs[i]));
  }

  return RpcGetTransaction(
    data: data,
    utime: utime,
    transactionId: transactionId,
    fee: fee,
    storageFee: storageFee,
    otherFee: otherFee,
    inMsg: inMsg,
    outMsgs: outMsgs,
  );
}

//

class RpcCallGetMethod extends RpcResponse {
  int gasUsed;
  int exitCode;
  List<List<String>> stack;

  RpcCallGetMethod({
    required this.gasUsed,
    required this.exitCode,
    required this.stack,
  });
}

RpcCallGetMethod _parseCallGetMethod(dynamic responseData) {
  var gasUsed = responseData['gas_used'] as int;
  var exitCode = responseData['exit_code'] as int;

  var rawStack = responseData['stack'] as List<dynamic>;
  var stack = <List<String>>[];

  for (var i = 0; i < rawStack.length; i += 1) {
    var rsi = rawStack[i] as List<dynamic>;
    var stacki = <String>[];

    for (var j = 0; j < rsi.length; j += 1) {
      if (rsi[j] is Map<String, dynamic>) {
        stacki.add(rsi[j]['bytes'] as String);
        continue;
      }

      if (rsi[j] is String) {
        stacki.add(rsi[j] as String);
        continue;
      }

      throw 'Item ${rsi[j]} is not a Map<String, dynamic> nor a String; current main stack is:\n$stack\n\nCurrently formed stack is:\n$stacki';
    }

    stack.add(stacki);
  }

  return RpcCallGetMethod(
    gasUsed: gasUsed,
    exitCode: exitCode,
    stack: stack,
  );
}
