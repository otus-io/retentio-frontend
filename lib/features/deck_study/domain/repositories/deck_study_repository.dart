import 'package:retentio/models/card.dart';
import 'package:retentio/models/tag.dart';

enum DeckStudySubmitType { review, hide }

class DeckStudySubmitRequest {
  const DeckStudySubmitRequest._({
    required this.deckId,
    required this.cardId,
    required this.type,
    this.intervalSeconds,
    this.hidden,
    this.lastReviewSeconds,
  });

  final String deckId;
  final String cardId;
  final DeckStudySubmitType type;
  final int? intervalSeconds;
  final bool? hidden;
  final int? lastReviewSeconds;

  factory DeckStudySubmitRequest.review({
    required String deckId,
    required String cardId,
    required int intervalSeconds,
    required int lastReviewSeconds,
  }) {
    return DeckStudySubmitRequest._(
      deckId: deckId,
      cardId: cardId,
      type: DeckStudySubmitType.review,
      intervalSeconds: intervalSeconds,
      lastReviewSeconds: lastReviewSeconds,
    );
  }

  factory DeckStudySubmitRequest.hide({
    required String deckId,
    required String cardId,
    bool hidden = true,
  }) {
    return DeckStudySubmitRequest._(
      deckId: deckId,
      cardId: cardId,
      type: DeckStudySubmitType.hide,
      hidden: hidden,
    );
  }
}

class DeckStudyLoadResult {
  const DeckStudyLoadResult({
    required this.cardDetail,
    this.nextCardDetail,
    this.refreshedCardsCount,
    this.refreshedDueCardsCount,
  });

  final CardDetail? cardDetail;

  /// Second-most urgent card, kept as a lookahead so the next review renders
  /// without waiting for another request. Null when the queue has no more cards.
  final CardDetail? nextCardDetail;

  /// Set when no due card exists and the deck detail endpoint is used to refresh.
  /// With a tag filter, total cards for that tag from card stats.
  final int? refreshedCardsCount;

  /// Live due count from card stats (deck-wide or tag-scoped).
  final int? refreshedDueCardsCount;

  bool get hasCard => cardDetail != null;
}

abstract class DeckStudyRepository {
  Future<DeckStudyLoadResult> loadNextDueCard({
    required String deckId,
    String? tagId,
  });

  Future<List<Tag>> loadDeckTags({required String deckId});

  Future<bool> submitCard(DeckStudySubmitRequest request);

  Future<bool> deleteCard({required String deckId, required String cardId});
}
