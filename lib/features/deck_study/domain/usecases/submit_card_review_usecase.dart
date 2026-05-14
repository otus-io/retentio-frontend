import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';

class SubmitCardReviewUseCase {
  const SubmitCardReviewUseCase(this._repository);

  final DeckStudyRepository _repository;

  Future<bool> review({
    required String deckId,
    required String cardId,
    required int intervalSeconds,
    required int lastReviewSeconds,
  }) {
    return _repository.submitCard(
      DeckStudySubmitRequest.review(
        deckId: deckId,
        cardId: cardId,
        intervalSeconds: intervalSeconds,
        lastReviewSeconds: lastReviewSeconds,
      ),
    );
  }

  Future<bool> hide({
    required String deckId,
    required String cardId,
    bool hidden = true,
  }) {
    return _repository.submitCard(
      DeckStudySubmitRequest.hide(
        deckId: deckId,
        cardId: cardId,
        hidden: hidden,
      ),
    );
  }
}
