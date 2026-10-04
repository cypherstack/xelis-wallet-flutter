import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:xelis_wallet_flutter/xelis_wallet_flutter.dart';

void main() {
  test(
    'native wallet retains identity and supports offline subscriptions',
    () async {
      await XelisWalletFlutter.initialize();
      final root = await Directory.systemTemp.createTemp(
        'xwf_wallet_contract_',
      );
      XelisWallet? wallet;
      try {
        final tables = await Directory('${root.path}/tables').create();
        final tablePath = '${tables.path}${Platform.pathSeparator}';
        wallet = await XelisWalletFlutter.createWallet(
          walletPath: '${root.path}/wallet',
          password: 'isolated-fixture-password',
          network: XelisNetwork.testnet,
          precomputedTableType: const XelisPrecomputedTableType.l1Low(),
          precomputedTablesPath: tablePath,
        );
        final address = wallet.address;
        final seed = await wallet.getSeed();
        // Compare predicates to keep secret material out of failure output.
        expect(seed.split(' ').length, 25);
        final engine = XelisWalletFlutter.createSeedSearchEngine(
          language: SeedLanguage.english,
        );
        try {
          expect(
            engine.findInvalidWords(words: seed.split(' ')).isEmpty,
            isTrue,
          );
        } finally {
          engine.dispose();
        }
        expect(await wallet.getXelisBalance(), BigInt.zero);
        expect(await wallet.pendingTransactions(), isEmpty);
        expect(
          await wallet.history(
            filter: XelisWalletHistoryFilter(page: BigInt.one),
          ),
          isEmpty,
        );
        final runtime = await wallet.subscribeRuntimeEvents();
        final business = await wallet.subscribeBusinessEvents();
        await runtime.cancel();
        await business.cancel();
        await wallet.close();
        wallet.dispose();
        wallet = null;
        wallet = await XelisWalletFlutter.openWallet(
          walletPath: '${root.path}/wallet',
          password: 'isolated-fixture-password',
          network: XelisNetwork.testnet,
          precomputedTableType: const XelisPrecomputedTableType.l1Low(),
          precomputedTablesPath: tablePath,
        );
        expect(wallet.address == address, isTrue);
        expect(await wallet.getSeed() == seed, isTrue);
      } finally {
        if (wallet != null) {
          await wallet.close();
          wallet.dispose();
        }
        await root.delete(recursive: true);
      }
    },
    timeout: const Timeout(Duration(minutes: 2)),
  );
}
