import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_fact.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/models/fact.dart';

void main() {
  test('OfflineCard round-trips and copyWith keeps identity', () {
    const card = OfflineCard(
      deckId: 'd1',
      id: 'c1',
      factId: 'f1',
      template: [
        [0],
        [1],
      ],
      lastReview: 10,
      dueDate: 20,
      createdAt: 5,
    );
    final back = OfflineCard.fromJson(card.toJson());
    expect(back.toJson(), card.toJson());

    final changed = card.copyWith(
      lastReview: 30,
      dueDate: 40,
      hidden: true,
      dirty: true,
    );
    expect(changed.id, 'c1');
    expect(changed.template, card.template);
    expect(changed.lastReview, 30);
    expect(changed.dueDate, 40);
    expect(changed.hidden, isTrue);
    expect(changed.dirty, isTrue);
    expect(card.copyWith().toJson(), card.toJson());
  });

  test('OfflineCard.fromJson defaults missing fields', () {
    final card = OfflineCard.fromJson({});
    expect(card.id, '');
    expect(card.template, isEmpty);
    expect(card.hidden, isFalse);
    expect(card.dirty, isFalse);
  });

  test('OfflineFact round-trips raw media ids and tag ids', () {
    const fact = OfflineFact(
      deckId: 'd1',
      id: 'f1',
      entries: [
        FactEntry(text: '猫', audio: 'aud1'),
        FactEntry(text: 'ねこ'),
      ],
      tagIds: ['t1'],
    );
    final back = OfflineFact.fromJson(fact.toJson());
    expect(back.entries.first.audio, 'aud1');
    expect(back.entries.last.text, 'ねこ');
    expect(back.tagIds, ['t1']);
    expect(OfflineFact.fromJson({}).entries, isEmpty);
  });

  test('OfflineFact keeps pinned media versions and keys media by them', () {
    const fact = OfflineFact(
      deckId: 'd1',
      id: 'f1',
      entries: [
        FactEntry(audio: 'a', image: 'b', video: 'c', json: 'd'),
        FactEntry(text: 'x'),
      ],
      tagIds: ['t1'],
      mediaVersions: {'a': 3},
    );
    final back = OfflineFact.fromJson(fact.toJson());
    expect(back.mediaVersions, {'a': 3});
    expect(back.mediaIds, {'a', 'b', 'c', 'd'});
    expect([back.mediaKey('a'), back.mediaKey('b')], ['a?v=3', 'b']);
    final legacy = OfflineFact.fromJson({'id': 'f1'});
    expect(legacy.mediaVersions, isNull);
    expect(legacy.toJson().containsKey('media_versions'), isFalse);
    expect(legacy.mediaKey('a'), 'a');
    final mixed = OfflineFact.fromJson({
      'media_versions': {'a': 1, 'b': 'x'},
    });
    expect(mixed.mediaVersions, {'a': 1});
    final unpinned = fact.withMediaVersions(null);
    expect(
      [unpinned.deckId, unpinned.id, unpinned.tagIds],
      [
        'd1',
        'f1',
        ['t1'],
      ],
    );
    expect(unpinned.entries, fact.entries);
    expect(unpinned.mediaVersions, isNull);
  });

  test('OfflineDeck round-trips and reports readiness', () {
    const deck = OfflineDeck(id: 'd1', name: 'N5', fields: ['Q', 'A']);
    expect(deck.isReady, isFalse);
    final ready = deck.copyWith(
      downloadedAt: 1,
      lastSyncedAt: 2,
      totalReviews: 3,
      totalReviewsToday: 4,
      tags: const [Tag(id: 't1', name: 'N5', description: '')],
      refreshedAt: 5,
    );
    expect(ready.isReady, isTrue);
    expect(ready.toJson()['refreshed_at'], 5);
    expect(OfflineDeck.fromJson(ready.toJson()).tags.single.name, 'N5');
    expect(OfflineDeck.fromJson(ready.toJson()).toJson(), ready.toJson());
    expect(deck.copyWith().toJson(), deck.toJson());
    expect(OfflineDeck.fromJson({}).fields, isEmpty);
    expect(OfflineDeck.fromJson({}).refreshedAt, 0);
  });

  test('StudySyncOperation builds separate review and hide bodies', () {
    const review = StudySyncOperation(
      operationId: 'op1',
      sequence: 1,
      deckId: 'd1',
      cardId: 'c1',
      type: StudySyncType.review,
      createdAt: 100,
      interval: 86400,
      lastReview: 100,
    );
    expect(review.toPatchBody(), {
      'card_id': 'c1',
      'interval': 86400,
      'last_review': 100,
    });

    const hide = StudySyncOperation(
      operationId: 'op2',
      sequence: 2,
      deckId: 'd1',
      cardId: 'c1',
      type: StudySyncType.hide,
      createdAt: 100,
    );
    expect(hide.toPatchBody(), {'card_id': 'c1', 'hidden': true});
  });

  test('StudySyncOperation round-trips and copyWith updates retry state', () {
    const op = StudySyncOperation(
      operationId: 'op1',
      sequence: 3,
      deckId: 'd1',
      cardId: 'c1',
      type: StudySyncType.hide,
      createdAt: 1,
      hidden: true,
    );
    final failed = op.copyWith(
      attempts: 2,
      httpAttempts: 1,
      nextRetryAt: 50,
      status: StudySyncStatus.failed,
      lastError: '400',
      maybeApplied: true,
    );
    final back = StudySyncOperation.fromJson(failed.toJson());
    expect(back.toJson(), failed.toJson());
    expect(back.type, StudySyncType.hide);
    expect(back.status, StudySyncStatus.failed);
    expect(back.httpAttempts, 1);
    expect(back.maybeApplied, isTrue);
    expect(op.maybeApplied, isFalse);
    expect(op.copyWith().toJson(), op.toJson());
    expect(failed.copyWith().lastError, '400');
    expect(failed.copyWith(clearLastError: true).lastError, isNull);

    final defaults = StudySyncOperation.fromJson({});
    expect(defaults.type, StudySyncType.review);
    expect(defaults.status, StudySyncStatus.pending);
    expect(defaults.httpAttempts, 0);
  });
}
