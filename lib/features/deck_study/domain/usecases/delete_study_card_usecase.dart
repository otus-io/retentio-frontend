import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';

class DeleteStudyCardUseCase {
  const DeleteStudyCardUseCase(this._repository);

  final DeckStudyRepository _repository;

  Future<bool> call({required String deckId, required String cardId}) {
    return _repository.deleteCard(deckId: deckId, cardId: cardId);
  }
}
