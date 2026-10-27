import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/features/offline_learning/domain/services/offline_deck_stats.dart';

const _day = Duration.secondsPerDay;
const _now = 10 * _day + 500;

OfflineCard _card(
  String id, {
  required int last,
  required int due,
  bool hidden = false,
  int createdAt = 0,
}) => OfflineCard(
  deckId: 'd1',
  id: id,
  factId: 'f',
  template: const [
    [0],
  ],
  lastReview: last,
  dueDate: due,
  hidden: hidden,
  createdAt: createdAt,
);

StudySyncOperation _op(String id, StudySyncType type, int createdAt) =>
    StudySyncOperation(
      operationId: id,
      sequence: 1,
      deckId: 'd1',
      cardId: 'c',
      type: type,
      createdAt: createdAt,
    );

void main() {
  test('matches backend ComputeStats rules', () {
    final stats = computeOfflineDeckStats(
      deck: const OfflineDeck(
        id: 'd1',
        name: 'N5',
        fields: [],
        totalReviews: 40,
        totalReviewsToday: 3,
        lastSyncedAt: _now - 10,
      ),
      cards: [
        _card('new', last: _now, due: _now + 1, createdAt: _now),
        _card('due', last: 100, due: _now - 1),
        _card('later', last: _now - 50, due: _now + 999),
        _card('hidden', last: 200, due: 300, hidden: true),
        _card('hiddenNew', last: 5, due: 6, hidden: true),
      ],
      factsCount: 4,
      queued: [
        _op('today', StudySyncType.review, _now),
        _op('yesterday', StudySyncType.review, _now - _day),
        _op('hide', StudySyncType.hide, _now),
      ],
      nowSec: _now,
    );

    expect(stats.cardsCount, 5);
    expect(stats.factsCount, 4);
    expect(stats.unseenCards, 1);
    expect(stats.reviewedCards, 3);
    expect(stats.dueCards, 1);
    expect(stats.hiddenCards, 2);
    expect(stats.newCardsToday, 1);
    expect(stats.totalReviews, 42);
    expect(stats.totalReviewsToday, 4);
    expect(stats.lastReviewedAt, _now - 50);
  });

  test('server today counter resets on a new UTC day', () {
    final stats = computeOfflineDeckStats(
      deck: const OfflineDeck(
        id: 'd1',
        name: 'N5',
        fields: [],
        totalReviewsToday: 3,
        downloadedAt: _now - _day,
      ),
      cards: const [],
      factsCount: 0,
      queued: const [],
      nowSec: _now,
    );

    expect(stats.totalReviewsToday, 0);
    expect(stats.lastReviewedAt, 0);
  });
}
