import 'dart:convert';
import 'dart:io';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:retentio/features/offline_learning/data/datasources/hive_offline_learning_store.dart';
import 'package:retentio/features/offline_learning/data/datasources/offline_store_cipher.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() => FlutterSecureStorage.setMockInitialValues({}));

  test('creates one key in secure storage and reuses it', () async {
    final first = await offlineStoreCipher();
    final stored = await const FlutterSecureStorage().read(
      key: offlineStoreKeyName,
    );
    final second = await offlineStoreCipher();

    expect(stored, isNotNull);
    expect(second.calculateKeyCrc(), first.calculateKeyCrc());
  });

  test('encrypted boxes are unreadable as plain text', () async {
    final dir = Directory.systemTemp.createTempSync('offline_cipher');
    addTearDown(() => dir.deleteSync(recursive: true));
    Hive.init(dir.path);
    final store = await HiveOfflineLearningStore.open(
      accountId: 'a',
      cipher: await offlineStoreCipher(),
    );
    await store.putDeck(
      const OfflineDeck(id: 'd1', name: 'secret-deck-name', fields: []),
    );
    await Hive.close();

    final raw = File(
      '${dir.path}/${HiveOfflineLearningStore.decksBox}.hive',
    ).readAsStringSync(encoding: const Latin1Codec());
    expect(raw, isNot(contains('secret-deck-name')));
  });
}
