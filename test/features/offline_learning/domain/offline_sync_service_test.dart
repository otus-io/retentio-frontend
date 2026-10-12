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
  @override
  Future<void> deleteMedia(String mediaId) => throw UnimplementedError();
  @override
  Future<void> removeDeck(String deckId) => throw UnimplementedError();
  @override
  Future<List<OfflineDeck>> getDecks() => throw UnimplementedError();
}

class _FakeRemote implements StudySyncRemoteDataSource {
  final patched = <String>[];
  final bodies = <Map<String, dynamic>>[];
  final countRequests = <String>[];
  final statusByOp = <String, int?>{};
  final dataByOp = <String, Map<String, dynamic>?>{};
  final messageByOp = <String, String>{};
  final apiErrorOps = <String>{};
  final counts = <String, OfflineDeckCounts>{};
  Completer<void>? gate;

  /// Throws once from the next [patchCard].
  bool throwOnPatch = false;

  @override
  Future<StudyPatchResult> patchCard(
    String deckId,
    Map<String, dynamic> body, {
    required String operationId,
  }) async {
    if (throwOnPatch) {
      throwOnPatch = false;
      throw StateError('boom');
    }
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
      isApiError: apiErrorOps.contains(operationId),
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
  int httpAttempts = 0,
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
  httpAttempts: httpAttempts,
  status: status,
);

const maxAttempts = OfflineSyncService.maxHttpAttempts;

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

  test('sends pending ops FIFO and stops at one still in backoff', () async {
    queue([
      _review('late', 3),
      _review('early', 1),
      _review('notDue', 2, nextRetryAt: _now + 1),
      _review('failed', 0, status: StudySyncStatus.failed),
    ]);

    await service().flush(force: true);

    expect(remote.patched, ['early']);
    expect(remote.bodies.first, {
      'card_id': 'c1',
      'interval': 60,
      'last_review': 900,
    });
    expect(store.ops.keys, unorderedEquals(['notDue', 'late', 'failed']));
  });

  test('retryNow sends ops still in backoff, in order', () async {
    queue([_review('late', 2), _review('notDue', 1, nextRetryAt: _now + 1)]);

    await service().flush(retryNow: true);

    expect(remote.patched, ['notDue', 'late']);
  });

  group('failed ops', () {
    setUp(
      () => queue([
        _review(
          'a',
          1,
          attempts: 9,
          httpAttempts: maxAttempts,
          nextRetryAt: _now + 60,
          status: StudySyncStatus.failed,
        ),
        _review('b', 2, cardId: 'c2', nextRetryAt: _now + 60),
      ]),
    );

    test('failedCount counts only failed ops', () async {
      expect(await service().failedCount(), 1);
    });

    test('retryFailed resets failed ops and sends them now', () async {
      final sync = service();

      final result = await sync.retryFailed();

      expect(result.sent, 2);
      expect(remote.patched, ['a', 'b']);
      expect(store.ops, isEmpty);
      expect(sync.phase.value, OfflineSyncPhase.synced);
    });

    test('retryFailed restarts the retry budget', () async {
      remote.statusByOp['a'] = 500;

      await service().retryFailed();

      final op = store.ops['a']!;
      expect(op.status, StudySyncStatus.pending);
      expect(op.attempts, 1);
      expect(op.httpAttempts, 1);
      expect(op.nextRetryAt, _now + 30);
    });

    test('discardFailed removes failed ops and recomputes phase', () async {
      final sync = service();
      online = false;
      await sync.flush();
      expect(sync.phase.value, OfflineSyncPhase.failed);

      await sync.discardFailed();

      expect(store.ops.keys, ['b']);
      expect(sync.phase.value, OfflineSyncPhase.offline);
      expect(remote.patched, isEmpty);
    });
  });

  test('keeps newer local schedule while the card is still queued', () async {
    store.cards['c1'] = _card('c1').copyWith(lastReview: 950, dueDate: 2000);
    queue([_review('o1', 1), _review('o2', 2)]);
    remote
      ..dataByOp['o1'] = {'last_review': 900, 'due_date': 960}
      ..statusByOp['o2'] = null;

    await service().flush(force: true);

    expect(store.cards['c1']!.dueDate, 2000);
    expect(store.cards['c1']!.dirty, isTrue);
  });

  test('keeps a review made while its earlier op was uploading', () async {
    store.cards['c1'] = _card('c1');
    queue([_review('o1', 1)]);
    remote
      ..dataByOp['o1'] = {'last_review': 900, 'due_date': 960}
      ..gate = Completer<void>();

    final flushing = service().flush(force: true);
    await Future<void>.delayed(Duration.zero);
    store.cards['c1'] = _card('c1').copyWith(lastReview: 950, dueDate: 2000);
    queue([_review('o2', 2, nextRetryAt: _now + 1)]);
    remote.gate!.complete();
    await flushing;

    expect(store.cards['c1']!.dueDate, 2000);
    expect(store.ops.keys, ['o2']);
  });

  test('a flush error reports failed instead of staying syncing', () async {
    queue([_review('o1', 1)]);
    final sync = service();
    remote.throwOnPatch = true;

    await expectLater(sync.flush(force: true), throwsStateError);

    expect(sync.phase.value, OfflineSyncPhase.failed);
  });

  group('overlapping flushes', () {
    late Completer<bool> gate;
    late OfflineSyncService sync;

    setUp(() {
      queue([_review('o1', 1)]);
      gate = Completer<bool>();
      sync = OfflineSyncService(
        store: store,
        remote: remote,
        isOnline: () => gate.future,
        nowSec: () => _now,
      );
    });

    test('a forced flush runs after a pending normal one', () async {
      final normal = sync.flush();
      final forced = sync.flush(force: true);
      gate.complete(true);

      expect((await normal).status, OfflineSyncStatus.skipped);
      expect((await forced).status, OfflineSyncStatus.synced);
      expect(remote.patched, ['o1']);
    });

    test('a weaker request joins the running flush', () async {
      final forced = sync.flush(force: true);
      final normal = sync.flush();
      gate.complete(true);

      expect(identical(await normal, await forced), isTrue);
      expect(remote.patched, ['o1']);
    });

    test('a stronger request still runs after a failed flush', () async {
      remote.throwOnPatch = true;
      final first = sync.flush(force: true);
      final retry = sync.flush(retryNow: true);
      gate.complete(true);
      await expectLater(first, throwsStateError);

      expect((await retry).status, OfflineSyncStatus.synced);
    });
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

  test('API 404 removes the op and the local card, then continues', () async {
    store.cards['c1'] = _card('c1');
    store.cards['c2'] = _card('c2');
    queue([_review('a', 1), _review('b', 2, cardId: 'c2')]);
    remote.statusByOp['a'] = 404;
    remote.apiErrorOps.add('a');

    final result = await service().flush(force: true);

    expect(result.status, OfflineSyncStatus.synced);
    expect(store.cards.keys, ['c2']);
    expect(store.ops, isEmpty);
    expect(remote.patched, ['a', 'b']);
  });

  test('404 without an API envelope keeps the card and retries', () async {
    store.cards['c1'] = _card('c1');
    queue([_review('a', 1)]);
    remote.statusByOp['a'] = 404;

    final result = await service().flush(force: true);

    expect(result.status, OfflineSyncStatus.partial);
    expect(store.cards.keys, ['c1']);
    final op = store.ops['a']!;
    expect(op.status, StudySyncStatus.pending);
    expect(op.nextRetryAt, _now + 30);
    expect(op.lastError, 'HTTP 404');
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

    test('network error stops ops of other cards too', () async {
      queue([_review('a', 1), _review('b', 2, cardId: 'c2')]);
      remote.statusByOp['a'] = null;

      await service().flush(force: true);

      expect(remote.patched, ['a']);
      expect(store.ops['a']!.httpAttempts, 0);
    });

    test('HTTP error holds back only later ops of the same card', () async {
      queue([
        _review('a', 1),
        _review('b', 2),
        _review('c', 3, cardId: 'c2'),
        _review('d', 4, deckId: 'd2'),
      ]);
      remote.statusByOp['a'] = 409;

      final result = await service().flush(force: true);

      expect(result.status, OfflineSyncStatus.partial);
      expect(remote.patched, ['a', 'c', 'd']);
      expect(store.ops.keys, ['a', 'b']);
      expect(store.ops['a']!.httpAttempts, 1);
      expect(store.ops['b']!.attempts, 0);
    });

    test('op in backoff holds back only later ops of its card', () async {
      queue([
        _review('wait', 1, nextRetryAt: _now + 1),
        _review('later', 2),
        _review('other', 3, cardId: 'c2'),
      ]);

      final result = await service().flush(force: true);

      expect(result.status, OfflineSyncStatus.synced);
      expect(remote.patched, ['other']);
      expect(store.ops.keys, ['wait', 'later']);
    });

    test('marks the op failed after max HTTP attempts', () async {
      queue([
        _review('a', 1, attempts: 9, httpAttempts: maxAttempts - 1),
        _review('b', 2),
      ]);
      remote.statusByOp['a'] = 422;
      remote.messageByOp['a'] = 'bad state';

      final result = await service().flush(force: true);

      final op = store.ops['a']!;
      expect(op.status, StudySyncStatus.failed);
      expect(op.lastError, 'bad state');
      expect(op.httpAttempts, maxAttempts);
      expect(result.failed, 1);
      expect(remote.patched, ['a', 'b']);
    });

    test('failed op does not hold back later ops of its card', () async {
      queue([_review('a', 1, status: StudySyncStatus.failed), _review('b', 2)]);

      await service().flush(force: true);

      expect(remote.patched, ['b']);
      expect(store.ops.keys, ['a']);
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
