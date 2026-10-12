import 'dart:io';

import 'package:flutter_test/flutter_test.dart';
import 'package:hive_ce/hive.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/features/offline_learning/data/datasources/hive_offline_learning_store.dart';
import 'package:retentio/features/offline_learning/data/repositories/offline_first_deck_study_repository.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/tag.dart';

class _FakeRemote implements DeckStudyRepository {
  int loads = 0;
  int submits = 0;
  bool deleteResult = true;

  @override
  Future<DeckStudyLoadResult> loadNextDueCard({
    required String deckId,
    String? tagId,
  }) async {
    loads++;
    return const DeckStudyLoadResult(cardDetail: null);
  }

  @override
  Future<bool> submitCard(DeckStudySubmitRequest request) async {
    submits++;
    return true;
  }

  @override
  Future<List<Tag>> loadDeckTags({required String deckId}) async => const [
    Tag(id: 't1', name: 'N5', description: ''),
  ];

  @override
  Future<bool> deleteCard({
    required String deckId,
    required String cardId,
  }) async => deleteResult;
}

const _now = 1000;

OfflineCard _card(String id, String factId, {int last = 0, int due = 2000}) =>
    OfflineCard(
      deckId: 'd1',
      id: id,
      factId: factId,
      template: const [
        [0],
        [1],
      ],
      lastReview: last,
      dueDate: due,
    );

void main() {
  late Directory dir;
  late HiveOfflineLearningStore store;
  late _FakeRemote remote;
  late int changes;
  late bool online;

  OfflineFirstDeckStudyRepository repo({
    Future<HiveOfflineLearningStore?>? s,
  }) => OfflineFirstDeckStudyRepository(
    store: s ?? Future.value(store),
    remote: remote,
    remoteMediaUrl: (id) => 'https://host/api/media/$id',
    onLocalChange: () => changes++,
    isOnline: () async => online,
    nowSec: () => _now,
    newOperationId: () => 'op-1',
  );

  Future<void> seedReadyDeck() async {
    await store.putDeck(
      const OfflineDeck(
        id: 'd1',
        name: 'N5',
        fields: ['Word', 'Meaning'],
        downloadedAt: 1,
      ),
    );
    await store.putFacts(const [
      OfflineFact(
        deckId: 'd1',
        id: 'f1',
        entries: [
          FactEntry(text: '猫', audio: 'aud1'),
          FactEntry(text: 'cat', image: 'img1'),
        ],
        tagIds: ['t1'],
      ),
      OfflineFact(
        deckId: 'd1',
        id: 'f2',
        entries: [
          FactEntry(text: '犬'),
          FactEntry(text: 'dog'),
        ],
      ),
    ]);
    final audio = File('${dir.path}/aud1.mp3')..createSync();
    await store.putMediaPath('aud1', audio.path);
    await store.putMediaPath('img1', '${dir.path}/deleted.png');
  }

  setUp(() async {
    dir = Directory.systemTemp.createTempSync('offline_repo');
    Hive.init(dir.path);
    store = await HiveOfflineLearningStore.open(accountId: 'u1');
    remote = _FakeRemote();
    changes = 0;
    online = true;
  });

  tearDown(() async {
    await Hive.deleteFromDisk();
    dir.deleteSync(recursive: true);
  });

  test('falls back to remote when the deck is not downloaded', () async {
    final r = repo();
    await r.loadNextDueCard(deckId: 'd1');
    expect(
      await r.submitCard(
        DeckStudySubmitRequest.hide(deckId: 'd1', cardId: 'c1'),
      ),
      isTrue,
    );
    await repo(s: Future.value(null)).loadNextDueCard(deckId: 'd1');
    expect(remote.loads, 2);
    expect(remote.submits, 1);
  });

  test('asks for a download when offline and not downloaded', () async {
    online = false;

    final result = await repo().loadNextDueCard(deckId: 'd1');

    expect(result.needsDownload, isTrue);
    expect(result.cardDetail, isNull);
    expect(remote.loads, 0);
  });

  test('keeps the first source decision for the whole session', () async {
    final r = repo();
    await r.loadNextDueCard(deckId: 'd1');
    await seedReadyDeck();
    await store.putCards([_card('c1', 'f1')]);
    await r.loadNextDueCard(deckId: 'd1');
    expect(remote.loads, 2);
  });

  test('deals card and lookahead locally with media and counts', () async {
    await seedReadyDeck();
    await store.putCards([
      _card('c1', 'f1', due: 900),
      _card('c2', 'f2', due: 4000),
      _card('c3', 'missing-fact'),
    ]);

    final result = await repo().loadNextDueCard(deckId: 'd1');

    expect(remote.loads, 0);
    final card = result.cardDetail!.card;
    expect(card.id, 'c1');
    expect(card.front.single.field, 'Word');
    expect(card.front.single.items.map((i) => i.value), [
      '猫',
      '${dir.path}/aud1.mp3',
    ]);
    expect(card.back.single.items.last.value, 'https://host/api/media/img1');
    expect(result.nextCardDetail!.card.id, 'c2');
    expect(result.refreshedCardsCount, isNull);
    expect(result.refreshedDueCardsCount, 1);
  });

  test('tag filter keeps only cards of tagged facts', () async {
    await seedReadyDeck();
    await store.putCards([_card('c1', 'f1'), _card('c2', 'f2', due: 1100)]);

    final result = await repo().loadNextDueCard(deckId: 'd1', tagId: 't1');

    expect(result.cardDetail!.card.id, 'c1');
    expect(result.nextCardDetail, isNull);
    expect(result.refreshedCardsCount, 1);
    expect(result.refreshedDueCardsCount, 0);
  });

  test('clamps a future last review and saves it', () async {
    await seedReadyDeck();
    await store.putCards([_card('c1', 'f1', last: 1500, due: 1501)]);

    final result = await repo().loadNextDueCard(deckId: 'd1');

    expect(result.cardDetail!.card.lastReview, _now);
    expect((await store.getCards('d1')).single.lastReview, _now);
  });

  test('empty deck returns no card and total counts', () async {
    await seedReadyDeck();
    final result = await repo().loadNextDueCard(deckId: 'd1');
    expect(result.cardDetail, isNull);
    expect(result.refreshedCardsCount, 0);
    expect(result.refreshedDueCardsCount, 0);
  });

  test('review updates the card and queues one operation', () async {
    await seedReadyDeck();
    await store.putCards([_card('c1', 'f1')]);

    final ok = await repo().submitCard(
      DeckStudySubmitRequest.review(
        deckId: 'd1',
        cardId: 'c1',
        intervalSeconds: 600,
        lastReviewSeconds: 5000,
      ),
    );

    expect(ok, isTrue);
    expect(changes, 1);
    final card = (await store.getCards('d1')).single;
    expect(card.lastReview, _now);
    expect(card.dueDate, _now + 600);
    expect(card.dirty, isTrue);
    final op = (await store.getOperations()).single;
    expect(op.operationId, 'op-1');
    expect(op.type, StudySyncType.review);
    expect(op.toPatchBody(), {
      'card_id': 'c1',
      'interval': 600,
      'last_review': _now,
    });
  });

  test('hide marks the card hidden and queues a hide operation', () async {
    await seedReadyDeck();
    await store.putCards([_card('c1', 'f1')]);

    await repo().submitCard(
      DeckStudySubmitRequest.hide(deckId: 'd1', cardId: 'c1'),
    );

    expect((await store.getCards('d1')).single.hidden, isTrue);
    expect((await store.getOperations()).single.toPatchBody(), {
      'card_id': 'c1',
      'hidden': true,
    });
  });

  test('submit for an unknown card fails without queueing', () async {
    await seedReadyDeck();
    final ok = await repo().submitCard(
      DeckStudySubmitRequest.hide(deckId: 'd1', cardId: 'nope'),
    );
    expect(ok, isFalse);
    expect(await store.getOperations(), isEmpty);
    expect(changes, 0);
  });

  test('default clock and id generator queue a usable operation', () async {
    await seedReadyDeck();
    await store.putCards([_card('c1', 'f1')]);
    final r = OfflineFirstDeckStudyRepository(
      store: Future.value(store),
      remote: remote,
      remoteMediaUrl: (id) => id,
    );

    await r.submitCard(DeckStudySubmitRequest.hide(deckId: 'd1', cardId: 'c1'));

    final op = (await store.getOperations()).single;
    expect(op.operationId, startsWith('op-'));
    expect(op.createdAt, greaterThan(_now));
  });

  test(
    'delete removes the local card only when the server deleted it',
    () async {
      await store.putCards([_card('c1', 'f1'), _card('c2', 'f1')]);
      final r = repo();

      remote.deleteResult = false;
      expect(await r.deleteCard(deckId: 'd1', cardId: 'c1'), isFalse);
      expect(await store.getCards('d1'), hasLength(2));

      remote.deleteResult = true;
      expect(await r.deleteCard(deckId: 'd1', cardId: 'c1'), isTrue);
      expect((await store.getCards('d1')).single.id, 'c2');
    },
  );

  test('tags come from the remote repository', () async {
    final tags = await repo().loadDeckTags(deckId: 'd1');
    expect(tags.single.id, 't1');
  });

  test('downloaded decks cache tags online and serve them offline', () async {
    await seedReadyDeck();
    final r = repo();

    expect((await r.loadDeckTags(deckId: 'd1')).single.id, 't1');
    expect((await store.getDeck('d1'))!.tags.single.name, 'N5');

    online = false;
    expect((await r.loadDeckTags(deckId: 'd1')).single.id, 't1');
  });
}
