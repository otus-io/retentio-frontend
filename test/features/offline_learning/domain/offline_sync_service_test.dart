import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/data/datasources/study_sync_remote_data_source.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/features/offline_learning/domain/repositories/offline_learning_store.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_sync_service.dart';

class _FakeStore implements OfflineLearningStore {
  final decks = <String, OfflineDeck>{};
  final cards = <String, OfflineCard>{};
  final ops = <String, StudySyncOperation>{};

  @override
  Future<OfflineDeck?> getDeck(String deckId) async => decks[deckId];

  @override
  Future<void> putDeck(OfflineDeck deck) async => decks[deck.id] = deck;

  @override
  Future<List<OfflineCard>> getCards(String deckId) async =>
      cards.values.where((c) => c.deckId == deckId).toList();

  @override
  Future<void> putCards(List<OfflineCard> list) async {
    for (final c in list) {
      cards[c.id] = c;
    }
  }

  @override
  Future<void> deleteCard(String deckId, String cardId) async =>
      cards.remove(cardId);

  @override
  Future<List<StudySyncOperation>> getOperations() async =>
      ops.values.toList()..sort((a, b) => a.sequence.compareTo(b.sequence));

  @override
  Future<void> updateOperation(StudySyncOperation op) async =>
      ops[op.operationId] = op;

  @override
  Future<void> removeOperation(String operationId) async =>
      ops.remove(operationId);

  @override
  Future<List<OfflineFact>> getFacts(String deckId) =>
      throw UnimplementedError();
  @override
  Future<void> putFacts(List<OfflineFact> facts) => throw UnimplementedError();
  @override
  Future<String?> getMediaPath(String mediaId) => throw UnimplementedError();
  @override
  Future<void> putMediaPath(String mediaId, String localPath) =>
      throw UnimplementedError();
  @override
  Future<void> applyLocalChange(OfflineCard card, StudySyncOperation op) =>
      throw UnimplementedError();
  @override
  Future<int> nextSequence() => throw UnimplementedError();
  @override
  Future<void> clear() => throw UnimplementedError();
}

class _FakeRemote implements StudySyncRemoteDataSource {
  final patched = <String>[];
  final bodies = <Map<String, dynamic>>[];
  final countRequests = <String>[];
  final statusByOp = <String, int?>{};
  final dataByOp = <String, Map<String, dynamic>?>{};
  final messageByOp = <String, String>{};
  final counts = <String, OfflineDeckCounts>{};
  Completer<void>? gate;

  @override
  Future<StudyPatchResult> patchCard(
    String deckId,
    Map<String, dynamic> body, {
    required String operationId,
  }) async {
    patched.add(operationId);
    bodies.add(body);
    await gate?.future;
    final status = statusByOp.containsKey(operationId)
        ? statusByOp[operationId]
        : 200;
    return StudyPatchResult(
      httpStatus: status,
      data: dataByOp[operationId],
      message: messageByOp[operationId],
    );
  }

  @override
  Future<OfflineDeckCounts?> fetchDeckCounts(String deckId) async {
    countRequests.add(deckId);
    return counts[deckId];
  }
}

const _now = 1000;

OfflineCard _card(String id, {String deckId = 'd1'}) => OfflineCard(
  deckId: deckId,
  id: id,
  factId: 'f-$id',
  template: const [
    [0],
    [1],
  ],
  lastReview: 1,
  dueDate: 2,
  dirty: true,
);

StudySyncOperation _review(
  String id,
  int seq, {
  String cardId = 'c1',
  String deckId = 'd1',
  int nextRetryAt = 0,
  int attempts = 0,
  StudySyncStatus status = StudySyncStatus.pending,
}) => StudySyncOperation(
  operationId: id,
  sequence: seq,
  deckId: deckId,
  cardId: cardId,
  type: StudySyncType.review,
  createdAt: 0,
  interval: 60,
  lastReview: 900,
  nextRetryAt: nextRetryAt,
  attempts: attempts,
  status: status,
);

StudySyncOperation _hide(String id, int seq, {String cardId = 'c1'}) =>
    StudySyncOperation(
      operationId: id,
      sequence: seq,
      deckId: 'd1',
      cardId: cardId,
      type: StudySyncType.hide,
      createdAt: 0,
      hidden: true,
    );

void main() {
  late _FakeStore store;
  late _FakeRemote remote;
  late bool online;

  OfflineSyncService service({int threshold = 100}) => OfflineSyncService(
    store: store,
    remote: remote,
    isOnline: () async => online,
    nowSec: () => _now,
    threshold: threshold,
  );

  void queue(List<StudySyncOperation> ops) {
    for (final op in ops) {
      store.ops[op.operationId] = op;
    }
  }

  setUp(() {
    store = _FakeStore();
    remote = _FakeRemote();
    online = true;
  });

  group('skip rules', () {
    test('skips when offline even with force', () async {
      queue([_review('a', 1)]);
      online = false;

      final result = await service().flush(force: true);

      expect(result.status, OfflineSyncStatus.skipped);
      expect(remote.patched, isEmpty);
    });

    test('skips below threshold unless forced', () async {
      queue([_review('a', 1), _review('b', 2)]);
      final sync = service(threshold: 3);

      expect((await sync.flush()).status, OfflineSyncStatus.skipped);
      expect(remote.patched, isEmpty);

      final forced = await sync.flush(force: true);
      expect(forced.status, OfflineSyncStatus.synced);
      expect(forced.sent, 2);
    });

    test('flushes without force once pending reaches threshold', () async {
      queue([_review('a', 1), _review('b', 2)]);

      final result = await service(threshold: 2).flush();

      expect(result.status, OfflineSyncStatus.synced);
      expect(remote.patched, ['a', 'b']);
    });

    test('failed ops do not count toward the threshold', () async {
      queue([_review('a', 1), _review('b', 2, status: StudySyncStatus.failed)]);

      expect(
        (await service(threshold: 2).flush()).status,
        OfflineSyncStatus.skipped,
      );
    });
  });

  group('phase', () {
    test('reports offline, pending, syncing, then synced', () async {
      final sync = service();
      expect(sync.phase.value, OfflineSyncPhase.synced);

      queue([_review('a', 1)]);
      online = false;
      await sync.flush();
      expect(sync.phase.value, OfflineSyncPhase.offline);

      online = true;
      await sync.flush();
      expect(sync.phase.value, OfflineSyncPhase.pending);

      remote.gate = Completer<void>();
      final running = sync.flush(force: true);
      await Future<void>.delayed(Duration.zero);
      expect(sync.phase.value, OfflineSyncPhase.syncing);
      remote.gate!.complete();
      await running;
      expect(sync.phase.value, OfflineSyncPhase.synced);
    });

    test('reports failed ops and a needed re-login', () async {
      final sync = service();
      queue([_review('a', 1, status: StudySyncStatus.failed)]);
      await sync.flush(force: true);
      expect(sync.phase.value, OfflineSyncPhase.failed);

      queue([_review('b', 2)]);
      remote.statusByOp['b'] = 401;
      await sync.flush(force: true);
      expect(sync.phase.value, OfflineSyncPhase.needsLogin);
    });

    test('retryNow sends ops still in backoff', () async {
      queue([_review('a', 1, nextRetryAt: _now + 60)]);
      final sync = service();

      await sync.flush(force: true);
      expect(remote.patched, isEmpty);

      await sync.flush(retryNow: true);
      expect(remote.patched, ['a']);
    });
  });

  test('sends due pending ops in ascending sequence only', () async {
    queue([
      _review('late', 3),
      _review('early', 1),
      _review('notDue', 2, nextRetryAt: _now + 1),
      _review('failed', 0, status: StudySyncStatus.failed),
    ]);

    await service().flush(force: true);

    expect(remote.patched, ['early', 'late']);
    expect(remote.bodies.first, {
      'card_id': 'c1',
      'interval': 60,
      'last_review': 900,
    });
    expect(store.ops.keys, unorderedEquals(['notDue', 'failed']));
  });

  group('2xx', () {
    test('confirms review schedule from the response', () async {
      store.cards['c1'] = _card('c1');
      queue([_review('a', 1)]);
      remote.dataByOp['a'] = {'last_review': 950, 'due_date': 1010};

      final result = await service().flush(force: true);

      final card = store.cards['c1']!;
      expect(card.lastReview, 950);
      expect(card.dueDate, 1010);
      expect(card.dirty, isFalse);
      expect(store.ops, isEmpty);
      expect(result.sent, 1);
    });

    test('confirms hidden status from the response', () async {
      store.cards['c1'] = _card('c1');
      queue([_hide('h', 1)]);
      remote.dataByOp['h'] = {'hidden_status': true};

      await service().flush(force: true);

      expect(store.cards['c1']!.hidden, isTrue);
      expect(store.cards['c1']!.dirty, isFalse);
      expect(remote.bodies.single, {'card_id': 'c1', 'hidden': true});
    });

    test('falls back to op values when the response has no data', () async {
      store.cards['c1'] = _card('c1');
      queue([_hide('h', 1)]);

      await service().flush(force: true);

      expect(store.cards['c1']!.hidden, isTrue);
      expect(store.cards['c1']!.lastReview, 1);
    });

    test('keeps dirty while another op for the card is queued', () async {
      store.cards['c1'] = _card('c1');
      queue([_review('a', 1), _review('b', 2, nextRetryAt: _now + 60)]);

      await service().flush(force: true);

      expect(store.cards['c1']!.dirty, isTrue);
      expect(store.ops.keys, ['b']);
    });

    test('skips confirmation when the card is not stored locally', () async {
      queue([_review('a', 1)]);

      final result = await service().flush(force: true);

      expect(result.status, OfflineSyncStatus.synced);
      expect(store.cards, isEmpty);
      expect(store.ops, isEmpty);
    });
  });

  test('401 stops immediately and keeps the queue', () async {
    queue([_review('a', 1), _review('b', 2), _review('c', 3)]);
    store.decks['d1'] = const OfflineDeck(id: 'd1', name: 'D', fields: []);
    remote.statusByOp['b'] = 401;

    final result = await service().flush(force: true);

    expect(result.status, OfflineSyncStatus.needsLogin);
    expect(result.sent, 1);
    expect(remote.patched, ['a', 'b']);
    expect(store.ops.keys, ['b', 'c']);
    expect(store.ops['b']!.attempts, 0);
    expect(remote.countRequests, isEmpty);
  });

  test('400 marks the op failed, keeps payload, and continues', () async {
    queue([_review('a', 1), _review('b', 2)]);
    remote.statusByOp['a'] = 400;
    remote.messageByOp['a'] = 'bad body';

    final result = await service().flush(force: true);

    expect(result.status, OfflineSyncStatus.partial);
    expect(result.failed, 1);
    expect(result.sent, 1);
    final failed = store.ops['a']!;
    expect(failed.status, StudySyncStatus.failed);
    expect(failed.lastError, 'bad body');
    expect(failed.interval, 60);
    expect(store.ops.keys, ['a']);
  });

  test('400 without a message records the HTTP status', () async {
    queue([_review('a', 1)]);
    remote.statusByOp['a'] = 400;

    await service().flush(force: true);

    expect(store.ops['a']!.lastError, 'HTTP 400');
  });

  test('404 removes the op and the local card, then continues', () async {
    store.cards['c1'] = _card('c1');
    store.cards['c2'] = _card('c2');
    queue([_review('a', 1), _review('b', 2, cardId: 'c2')]);
    remote.statusByOp['a'] = 404;

    final result = await service().flush(force: true);

    expect(result.status, OfflineSyncStatus.synced);
    expect(store.cards.keys, ['c2']);
    expect(store.ops, isEmpty);
    expect(remote.patched, ['a', 'b']);
  });

  group('retryable errors', () {
    test('network error schedules backoff and stops the batch', () async {
      queue([_review('a', 1), _review('b', 2)]);
      remote.statusByOp['a'] = null;

      final result = await service().flush(force: true);

      expect(result.status, OfflineSyncStatus.partial);
      expect(remote.patched, ['a']);
      expect(store.ops['b']!.attempts, 0);
      final op = store.ops['a']!;
      expect(op.attempts, 1);
      expect(op.nextRetryAt, _now + 30);
      expect(op.lastError, 'network error');
      expect(op.status, StudySyncStatus.pending);
    });

    test('other status without a message records the status', () async {
      queue([_review('a', 1)]);
      remote.statusByOp['a'] = 503;

      await service().flush(force: true);

      expect(store.ops['a']!.lastError, 'HTTP 503');
    });

    for (final (attempts, delay) in [
      (1, 120),
      (2, 600),
      (3, 1800),
      (4, 7200),
      (9, 7200),
    ]) {
      test('attempt ${attempts + 1} waits $delay s', () async {
        queue([_review('a', 1, attempts: attempts)]);
        remote.statusByOp['a'] = 500;
        remote.messageByOp['a'] = 'server down';

        await service().flush(force: true);

        expect(store.ops['a']!.attempts, attempts + 1);
        expect(store.ops['a']!.nextRetryAt, _now + delay);
        expect(store.ops['a']!.lastError, 'server down');
      });
    }
  });

  test('refreshes counts only for decks with successful ops', () async {
    store.decks['d1'] = const OfflineDeck(id: 'd1', name: 'D1', fields: []);
    store.decks['d2'] = const OfflineDeck(id: 'd2', name: 'D2', fields: []);
    queue([
      _review('a', 1),
      _review('b', 2, deckId: 'd2', cardId: 'c2'),
      _review('c', 3, deckId: 'd3', cardId: 'c3'),
      _review('d', 4, deckId: 'd4', cardId: 'c4'),
    ]);
    remote.statusByOp['b'] = 400;
    remote.counts['d1'] = const OfflineDeckCounts(
      totalReviews: 9,
      totalReviewsToday: 4,
    );
    remote.counts['d3'] = const OfflineDeckCounts(
      totalReviews: 1,
      totalReviewsToday: 1,
    );

    await service().flush(force: true);

    expect(remote.countRequests, ['d1', 'd3', 'd4']);
    final d1 = store.decks['d1']!;
    expect(d1.totalReviews, 9);
    expect(d1.totalReviewsToday, 4);
    expect(d1.lastSyncedAt, _now);
    expect(store.decks['d2']!.lastSyncedAt, 0);
    expect(store.decks.keys, ['d1', 'd2']);
  });

  test('concurrent flush calls share one in-flight run', () async {
    queue([_review('a', 1)]);
    remote.gate = Completer<void>();
    final sync = service();

    final first = sync.flush(force: true);
    final second = sync.flush(force: true);
    await Future<void>.delayed(Duration.zero);
    remote.gate!.complete();

    expect(identical(first, second), isTrue);
    expect((await first).sent, 1);
    expect(remote.patched, ['a']);

    remote.gate = null;
    queue([_review('b', 2)]);
    expect((await sync.flush(force: true)).sent, 1);
  });
}
