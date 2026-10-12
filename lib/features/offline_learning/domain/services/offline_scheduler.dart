import 'dart:math' as math;
import 'dart:typed_data';

import 'package:retentio/features/offline_learning/domain/entities/offline_card.dart';

/// Result of local next-card selection (mirrors backend `GetNextCard`).
class OfflineSelection {
  const OfflineSelection({
    this.card,
    this.urgency = 0,
    this.nextCard,
    this.nextUrgency = 0,
  });

  final OfflineCard? card;
  final double urgency;
  final OfflineCard? nextCard;
  final double nextUrgency;

  bool get isEmpty => card == null;
}

/// Picks the most urgent card plus a lookahead card; ties go to the smaller id.
OfflineSelection selectNextCards(
  List<OfflineCard> cards, {
  required int nowSec,
  Set<String>? allowedFactIds,
}) {
  final ranked = <(OfflineCard, double)>[];
  for (final card in cards) {
    if (allowedFactIds != null && !allowedFactIds.contains(card.factId)) {
      continue;
    }
    if (card.hidden) continue;
    final span = card.dueDate - card.lastReview;
    if (span <= 0) continue;
    ranked.add((card, _float32Urgency(nowSec - card.lastReview, span)));
  }
  if (ranked.isEmpty) return const OfflineSelection();
  ranked.sort((a, b) {
    final byUrgency = b.$2.compareTo(a.$2);
    return byUrgency != 0 ? byUrgency : a.$1.id.compareTo(b.$1.id);
  });
  final second = ranked.length > 1 ? ranked[1] : null;
  return OfflineSelection(
    card: ranked[0].$1,
    urgency: ranked[0].$2,
    nextCard: second?.$1,
    nextUrgency: second?.$2 ?? 0,
  );
}

double _float32Urgency(int elapsed, int span) {
  final f = Float32List(1);
  double toF32(double v) => (f..[0] = v)[0];
  return toF32(toF32(elapsed.toDouble()) / toF32(span.toDouble()));
}

/// Moves a future `lastReview` back to [nowSec], keeping the interval.
OfflineCard clampFutureLastReview(OfflineCard card, int nowSec) {
  if (card.lastReview <= nowSec) return card;
  return card.copyWith(
    lastReview: nowSec,
    dueDate: nowSec + (card.dueDate - card.lastReview),
  );
}

/// Local equivalent of a review PATCH (`interval`, `last_review`).
OfflineCard applyReview(
  OfflineCard card, {
  required int intervalSec,
  required int lastReviewSec,
  required int nowSec,
}) {
  final last = math.min(lastReviewSec, nowSec);
  return card.copyWith(
    lastReview: last,
    dueDate: last + intervalSec,
    dirty: true,
  );
}

/// Local equivalent of a hide PATCH.
OfflineCard applyHide(OfflineCard card) =>
    card.copyWith(hidden: true, dirty: true);
