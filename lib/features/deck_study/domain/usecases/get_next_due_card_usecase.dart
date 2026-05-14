import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';

class GetNextDueCardUseCase {
  const GetNextDueCardUseCase(this._repository);

  final DeckStudyRepository _repository;

  Future<DeckStudyLoadResult> call({required String deckId}) {
    return _repository.loadNextDueCard(deckId: deckId);
  }
}
