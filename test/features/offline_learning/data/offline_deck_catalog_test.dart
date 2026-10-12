import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:retentio/features/offline_learning/data/datasources/hive_offline_learning_store.dart';
import 'package:retentio/features/offline_learning/data/offline_deck_catalog.dart';
import 'package:retentio/features/offline_learning/data/offline_package_downloader.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_sync_service.dart';
import 'package:retentio/features/offline_learning/offline_learning_session.dart';
import 'package:retentio/models/deck.dart';

class _Unused implements OfflinePackageDownloader, OfflineSyncService {
  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}

Deck _remote(String id, {int due = 99}) => Deck.fromJson({
  'id': id,
  'name': 'Remote $id',
  'owner': {'username': 'u', 'email': 'e'},
  'stats': {'due_cards': due},
});

void main() {
  late Directory dir;
  late HiveOfflineLearningStore store;
  late bool online;

  OfflineDeckCatalog catalog({
    Future<OfflineLearningSession?>? session,
    bool realClock = false,
  }) => OfflineDeckCatalog(
    session: () =>
        session ??
        Future.value(
          OfflineLearningSession(
            accountId: 'u1',
            store: store,
            downloader: _Unused(),
            sync: _Unused(),
            mediaRootDir: dir.path,
          ),
        ),
    isOnline: () async => online,
    nowSec: realClock ? null : () => 1000,
  );

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offline_catalog');
    Hive.init(dir.path);
    store = await HiveOfflineLearningStore.open(accountId: 'u1');
    online = true;
    await store.putDeck(
      const OfflineDeck(
        id: 'd1',
        name: 'Local',
        fields: ['W'],
        downloadedAt: 1,
      ),
    );
    await store.putDeck(
      const OfflineDeck(id: 'd2', name: 'Partial', fields: []),
    );
    await store.putCards(const [
      OfflineCard(
        deckId: 'd1',
        id: 'c1',
        factId: 'f1',
        template: [
          [0],
        ],
        lastReview: 10,
        dueDate: 900,
      ),
    ]);
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    dir.deleteSync(recursive: true);
  });

  test(
    'online: downloaded decks get local stats, others stay remote',
    () async {
      final decks = await catalog().decks(
        () async => [_remote('d1'), _remote('d2'), _remote('d3')],
      );

      expect(decks.map((d) => d.id), ['d1', 'd2', 'd3']);
      expect(decks[0].name, 'Remote d1');
      expect(decks[0].owner.username, 'u');
      expect(decks[0].stats.dueCards, 1);
      expect(decks[0].stats.cardsCount, 1);
      expect(decks[1].stats.dueCards, 99);
    },
  );

  test('offline: lists only downloaded decks from local data', () async {
    online = false;
    var fetched = false;

    final decks = await catalog().decks(() async {
      fetched = true;
      return [];
    });

    expect(fetched, isFalse);
    expect(decks.single.name, 'Local');
    expect(decks.single.fields, ['W']);
    expect(decks.single.stats.dueCards, 1);
    expect(
      (await catalog(realClock: true).decks(() async => [])).single.id,
      'd1',
    );
  });

  test('server unreachable: falls back to downloaded decks', () async {
    final decks = await catalog().decks(
      () async => throw const SocketException('down'),
    );

    expect(decks.single.name, 'Local');
  });

  test('server unreachable with nothing downloaded: rethrows', () async {
    await store.removeDeck('d1');

    await expectLater(
      catalog().decks(() async => throw const SocketException('down')),
      throwsA(isA<SocketException>()),
    );
  });

  test('remove drops the downloaded deck', () async {
    await catalog().remove('d1');
    expect(await store.getDeck('d1'), isNull);

    await catalog(session: Future.value(null)).remove('d2');
    expect(await store.getDeck('d2'), isNotNull);
  });

  test('without a session the remote list is returned as is', () async {
    final remote = [_remote('d1')];

    expect(
      await catalog(session: Future.value(null)).decks(() async => remote),
      same(remote),
    );
    expect(
      await catalog(
        session: Future.error(StateError('no storage')),
      ).decks(() async => remote),
      same(remote),
    );
  });
}
