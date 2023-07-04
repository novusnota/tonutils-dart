@TestOn('vm')

import 'dart:io' show File;
import 'package:tonutils/tonutils.dart' show InternalAddress, TonJsonRpc, TiInt;
import 'package:test/test.dart' show TestOn, group, test; // expect

void main() {
  var apiKeyMainnet =
      File('.api_key_mainnet').readAsStringSync().trim().toLowerCase();

  var client = TonJsonRpc(
    'https://toncenter.com/api/v2/jsonRPC',
    apiKeyMainnet.isNotEmpty ? apiKeyMainnet : null,
  );

  final testAddress =
      InternalAddress.parse('EQCD39VS5jcptHL8vMjEXrzGaRcCVYto7HUn4bpAOg8xqB2N');

  group('client/jsonrpc', () {
    test('getContractState', () async {
      var state = await client.getContractState(testAddress);
      print(state.state);
    });

    test('getBalance', () async {
      var balance = await client.getBalance(testAddress);
      print(balance);
    });

    test('getTransactions', () async {
      var transactions = await client.getTransactions(testAddress, limit: 3);
      print(transactions.firstOrNull?.address);
    });

    test('getTransaction', () async {
      final lt = '38873714000001';
      final hash = '5cflHlU57e42_p-gRd5a6YnPtxXjA-GhbynUBwMS8TQ=';

      var info = await client.getTransaction(testAddress, lt, hash);
      print(info!);
    });

    test('runMethod', () async {
      var seqno = await client.runMethod(testAddress, 'seqno');
      print(seqno.gasUsed);

      if (seqno.stack.items.firstOrNull is TiInt) {
        print((seqno.stack.items.first as TiInt).value);
      } else {
        print(seqno.stack.items);
      }
    });

    test('getMasterchainInfo', () async {
      var info = await client.getMasterchainInfo();

      print('Init seqno: ${info.initSeqno}');
      print('Latest seqno: ${info.latestSeqno}');

      var shardInfo = await client.getShardTransactions(
        info.workchain,
        info.latestSeqno,
        info.shard,
      );
      var workchainShards = await client.getWorkchainShards(info.latestSeqno);

      print('Shard info: $shardInfo');
      print('Workchain shards: $workchainShards');
    });
  });
}
