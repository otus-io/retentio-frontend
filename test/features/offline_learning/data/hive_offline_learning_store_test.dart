import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:retentio/features/offline_learning/data/datasources/hive_offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/models/fact.dart';

OfflineCard _card(String id, {String deckId = 'd1', int due = 0}) =>
    OfflineCard(
      deckId: deckId,
      id: id,
      factId: 'f$id',
      template: const [
        [0],
        [1],
      ],
      lastReview: 0,
      dueDate: due,
    );

StudySyncOperation _op(String id, int sequence) => StudySyncOperation(
  operationId: id,
  sequence: sequence,
  deckId: 'd1',
  cardId: 'c1',
  type: StudySyncType.review,
  createdAt: 1,
  interval: 60,
  lastReview: 1,
);

void main() {
  late Directory dir;
  late HiveOfflineLearningStore store;

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offline_store_test');
    Hive.init(dir.path);
    store = await HiveOfflineLearningStore.open(accountId: 'alice');
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    dir.deleteSync(recursive: true);
  });

  test('deck upsert and read', () async {
    expect(await store.getDeck('d1'), isNull);
    await store.putDeck(
      const OfflineDeck(id: 'd1', name: 'One', fields: ['en'], downloadedAt: 5),
    );
    final deck = await store.getDeck('d1');
    expect(deck?.name, 'One');
    expect(deck?.isReady, isTrue);
  });

  test('facts are scoped by deck and upserted', () async {
    await store.putFacts(const [
      OfflineFact(
        deckId: 'd1',
        id: 'f1',
        entries: [FactEntry(text: 'a')],
      ),
      OfflineFact(deckId: 'd2', id: 'f2', entries: []),
    ]);
    await store.putFacts(const [
      OfflineFact(
        deckId: 'd1',
        id: 'f1',
        entries: [FactEntry(text: 'b')],
      ),
    ]);
    final facts = await store.getFacts('d1');
    expect(facts.map((f) => f.id), ['f1']);
    expect(facts.single.entries.single.text, 'b');
  });

  test('cards are sorted, deck-scoped, upserted and deletable', () async {
    await store.putCards([
      _card('c3'),
      _card('c1'),
      _card('c2'),
      _card('x', deckId: 'd2'),
    ]);
    await store.putCards([_card('c2', due: 99)]);
    var cards = await store.getCards('d1');
    expect(cards.map((c) => c.id), ['c1', 'c2', 'c3']);
    expect(cards[1].dueDate, 99);

    await store.deleteCard('d1', 'c2');
    cards = await store.getCards('d1');
    expect(cards.map((c) => c.id), ['c1', 'c3']);
    expect((await store.getCards('d2')).map((c) => c.id), ['x']);
  });

  test('accounts are isolated', () async {
    await store.putDeck(const OfflineDeck(id: 'd1', name: 'One', fields: []));
    await store.putCards([_card('c1')]);
    await store.putFacts(const [
      OfflineFact(deckId: 'd1', id: 'f1', entries: []),
    ]);
    await store.putMediaPath('m1', '/tmp/m1');
    await store.applyLocalChange(
      _card('c1'),
      _op('o1', await store.nextSequence()),
    );

    final bob = await HiveOfflineLearningStore.open(accountId: 'bob');
    expect(await bob.getDeck('d1'), isNull);
    expect(await bob.getDecks(), isEmpty);
    expect((await store.getDecks()).single.name, 'One');
    expect(await bob.getCards('d1'), isEmpty);
    expect(await bob.getFacts('d1'), isEmpty);
    expect(await bob.getMediaPath('m1'), isNull);
    expect(await bob.getOperations(), isEmpty);
    expect(await bob.nextSequence(), 1);
  });

  test('removeDeck deletes the deck rows and its queued operations', () async {
    for (final id in ['d1', 'd2']) {
      await store.putDeck(OfflineDeck(id: id, name: id, fields: const []));
      await store.putFacts([
        OfflineFact(deckId: id, id: 'f$id', entries: const []),
      ]);
      await store.putCards([_card('c$id', deckId: id)]);
    }
    await store.applyLocalChange(_card('cd1'), _op('o1', 1));
    await store.putMediaPath('m1', '/m1');

    await store.removeDeck('d1');
    await store.deleteMedia('m1');

    expect(await store.getDeck('d1'), isNull);
    expect(await store.getFacts('d1'), isEmpty);
    expect(await store.getCards('d1'), isEmpty);
    expect(await store.getOperations(), isEmpty);
    expect(await store.getMediaPath('m1'), isNull);
    expect(await store.getDeck('d2'), isNotNull);
    expect(await store.getCards('d2'), hasLength(1));
  });

  test('clear removes only this account', () async {
    final bob = await HiveOfflineLearningStore.open(accountId: 'bob');
    for (final s in [store, bob]) {
      await s.putDeck(const OfflineDeck(id: 'd1', name: 'One', fields: []));
      await s.putFacts(const [
        OfflineFact(deckId: 'd1', id: 'f1', entries: []),
      ]);
      await s.putMediaPath('m1', '/tmp/m1');
      await s.applyLocalChange(_card('c1'), _op('o1', await s.nextSequence()));
    }

    await store.clear();

    expect(await store.getDeck('d1'), isNull);
    expect(await store.getCards('d1'), isEmpty);
    expect(await store.getFacts('d1'), isEmpty);
    expect(await store.getMediaPath('m1'), isNull);
    expect(await store.getOperations(), isEmpty);
    expect(await store.nextSequence(), 1);
    expect(await bob.getDeck('d1'), isNotNull);
    expect(await bob.getOperations(), hasLength(1));
  });

  test('applyLocalChange writes card and operation', () async {
    await store.putCards([_card('c1')]);
    await store.applyLocalChange(
      _card('c1').copyWith(dueDate: 7, dirty: true),
      _op('o1', 1),
    );
    final card = (await store.getCards('d1')).single;
    expect(card.dueDate, 7);
    expect(card.dirty, isTrue);
    expect((await store.getOperations()).single.operationId, 'o1');
  });

  test('operations are ordered by sequence, updatable and removable', () async {
    await store.applyLocalChange(_card('c1'), _op('o3', 3));
    await store.applyLocalChange(_card('c1'), _op('o1', 1));
    await store.applyLocalChange(_card('c1'), _op('o2', 2));
    expect((await store.getOperations()).map((o) => o.operationId), [
      'o1',
      'o2',
      'o3',
    ]);

    await store.updateOperation(
      _op('o2', 2).copyWith(attempts: 2, status: StudySyncStatus.failed),
    );
    await store.removeOperation('o1');
    final ops = await store.getOperations();
    expect(ops.map((o) => o.operationId), ['o2', 'o3']);
    expect(ops.first.attempts, 2);
    expect(ops.first.status, StudySyncStatus.failed);
  });

  test('nextSequence persists across reopen', () async {
    expect(await store.nextSequence(), 1);
    expect(await store.nextSequence(), 2);
    await Hive.close();
    store = await HiveOfflineLearningStore.open(accountId: 'alice');
    expect(await store.nextSequence(), 3);
  });

  test('data survives reopen from disk', () async {
    await store.putFacts(const [
      OfflineFact(
        deckId: 'd1',
        id: 'f1',
        entries: [FactEntry(text: 'a')],
      ),
    ]);
    await store.putCards([_card('c1')]);
    await Hive.close();
    store = await HiveOfflineLearningStore.open(accountId: 'alice');
    expect((await store.getFacts('d1')).single.entries.single.text, 'a');
    expect((await store.getCards('d1')).single.template, [
      [0],
      [1],
    ]);
  });

  test('media path get and put', () async {
    expect(await store.getMediaPath('m1'), isNull);
    await store.putMediaPath('m1', '/files/m1.mp3');
    expect(await store.getMediaPath('m1'), '/files/m1.mp3');
  });

  test('open accepts a cipher', () async {
    await Hive.close();
    final cipher = HiveAesCipher(List<int>.generate(32, (i) => i));
    store = await HiveOfflineLearningStore.open(
      accountId: 'alice',
      cipher: cipher,
    );
    await store.putMediaPath('m1', '/p');
    expect(await store.getMediaPath('m1'), '/p');
  });
}
