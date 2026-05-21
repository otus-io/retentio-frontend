import 'package:retentio/models/card.dart';

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
    this.refreshedCardsCount,
  });

  final CardDetail? cardDetail;

  /// Set when no due card exists and the deck detail endpoint is used to refresh.
  final int? refreshedCardsCount;

  bool get hasCard => cardDetail != null;
}

abstract class DeckStudyRepository {
  Future<DeckStudyLoadResult> loadNextDueCard({required String deckId});

  Future<bool> submitCard(DeckStudySubmitRequest request);

  Future<bool> deleteCard({required String deckId, required String cardId});
}
