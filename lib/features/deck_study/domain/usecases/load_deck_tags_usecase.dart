import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/models/tag.dart';

class LoadDeckTagsUseCase {
  const LoadDeckTagsUseCase(this._repository);

  final DeckStudyRepository _repository;

  Future<List<Tag>> call({required String deckId}) {
    return _repository.loadDeckTags(deckId: deckId);
  }
}
