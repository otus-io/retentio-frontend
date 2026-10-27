import 'dart:math';

import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';
import 'package:retentio/features/offline_learning/domain/entities/offline_deck.dart';
import 'package:retentio/features/offline_learning/domain/entities/study_sync_operation.dart';
import 'package:retentio/models/deck.dart';

/// Backend `ComputeStats` over local cards. Review counters are the server
/// values from the last flush plus reviews still queued locally.
DeckStats computeOfflineDeckStats({
  required OfflineDeck deck,
  required List<OfflineCard> cards,
  required int factsCount,
  required List<StudySyncOperation> queued,
  required int nowSec,
}) {
  bool unseen(OfflineCard c) => c.dueDate - c.lastReview == 1;
  final today = _utcDay(nowSec);
  final countersDay = _utcDay(max(deck.lastSyncedAt, deck.downloadedAt));
  final seen = cards.where((c) => !unseen(c));
  final pendingReviews = queued.where(
    (op) => op.deckId == deck.id && op.type == StudySyncType.review,
  );
  return DeckStats(
    cardsCount: cards.length,
    factsCount: factsCount,
    unseenCards: cards.where((c) => !c.hidden && unseen(c)).length,
    reviewedCards: seen.length,
    dueCards: cards.where((c) => !c.hidden && c.dueDate <= nowSec).length,
    hiddenCards: cards.where((c) => c.hidden).length,
    newCardsToday: cards.where((c) => _utcDay(c.createdAt) == today).length,
    totalReviews: deck.totalReviews + pendingReviews.length,
    totalReviewsToday:
        (countersDay == today ? deck.totalReviewsToday : 0) +
        pendingReviews.where((op) => _utcDay(op.createdAt) == today).length,
    lastReviewedAt: seen.fold(0, (latest, c) => max(latest, c.lastReview)),
  );
}

int _utcDay(int unixSec) => unixSec ~/ Duration.secondsPerDay;
