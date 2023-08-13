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

  final mainnetAddress = InternalAddress.parse(
      'EQDntPGyh1m8HMZ6i8LSuVCh1hyTh7ENXbRMaUNk8h6bxySU'); // TON Footsteps

  group('client/jsonrpc', () {
    test('getContractState', () async {
      var state = await client.getContractState(mainnetAddress);
      print(state.state);
    });

    test('getBalance', () async {
      var balance = await client.getBalance(mainnetAddress);
      print(balance);
    });

    test('getTransactions', () async {
      var transactions = await client.getTransactions(mainnetAddress, limit: 3);
      print(transactions.firstOrNull?.address);
    });

    test('getTransaction', () async {
      final lt = '39205147000003';
      final hash = 'WbkZIbnQbdqPB9zYYeaFBxWFqgRKscX48q2XPbBA22Y=';

      var info = await client.getTransaction(mainnetAddress, lt, hash);
      print(info!);
    });

    test('runMethod', () async {
      var seqno = await client.runMethod(mainnetAddress, 'seqno');
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
