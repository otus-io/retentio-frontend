import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/features/deck_study/domain/usecases/delete_study_card_usecase.dart';
import 'package:retentio/features/deck_study/domain/usecases/get_next_due_card_usecase.dart';
import 'package:retentio/features/deck_study/domain/usecases/load_deck_tags_usecase.dart';
import 'package:retentio/features/deck_study/domain/usecases/submit_card_review_usecase.dart';
import 'package:retentio/features/deck_study/presentation/bloc/deck_study_bloc.dart';
import 'package:retentio/features/deck_study/presentation/bloc/deck_study_event.dart';
import 'package:retentio/models/tag.dart';

class FakeDeckStudyRepository implements DeckStudyRepository {
  FakeDeckStudyRepository({
    List<DeckStudyLoadResult>? loadResults,
    this.submitShouldSucceed = true,
    this.deleteShouldSucceed = true,
    this.fallbackResult = const DeckStudyLoadResult(cardDetail: null),
  }) : _loadResults = List<DeckStudyLoadResult>.from(loadResults ?? const []);

  final List<DeckStudyLoadResult> _loadResults;
  final bool submitShouldSucceed;
  final bool deleteShouldSucceed;
  final DeckStudyLoadResult fallbackResult;

  int loadCalls = 0;
  int reviewSubmitCalls = 0;
  int hideSubmitCalls = 0;
  int deleteCalls = 0;

  @override
  Future<List<Tag>> loadDeckTags({required String deckId}) async => const [];

  @override
  Future<DeckStudyLoadResult> loadNextDueCard({
    required String deckId,
    String? tagId,
  }) async {
    loadCalls += 1;
    if (_loadResults.isEmpty) return fallbackResult;
    final index = loadCalls - 1;
    if (index >= 0 && index < _loadResults.length) {
      return _loadResults[index];
    }
    return _loadResults.last;
  }

  @override
  Future<bool> submitCard(DeckStudySubmitRequest request) async {
    if (request.type == DeckStudySubmitType.hide) {
      hideSubmitCalls += 1;
    } else {
      reviewSubmitCalls += 1;
    }
    return submitShouldSucceed;
  }

  @override
  Future<bool> deleteCard({
    required String deckId,
    required String cardId,
  }) async {
    deleteCalls += 1;
    return deleteShouldSucceed;
  }
}

class FakeDeckStudyBlocHarness {
  FakeDeckStudyBlocHarness._({required this.repository, required this.bloc});

  final FakeDeckStudyRepository repository;
  final DeckStudyBloc bloc;

  factory FakeDeckStudyBlocHarness({
    required String deckId,
    List<DeckStudyLoadResult>? loadResults,
    bool submitShouldSucceed = true,
    bool deleteShouldSucceed = true,
    DeckStudyLoadResult fallbackResult = const DeckStudyLoadResult(
      cardDetail: null,
    ),
    bool startImmediately = true,
  }) {
    final repository = FakeDeckStudyRepository(
      loadResults: loadResults,
      submitShouldSucceed: submitShouldSucceed,
      deleteShouldSucceed: deleteShouldSucceed,
      fallbackResult: fallbackResult,
    );

    final bloc = DeckStudyBloc(
      deckId: deckId,
      getNextDueCardUseCase: GetNextDueCardUseCase(repository),
      submitCardReviewUseCase: SubmitCardReviewUseCase(repository),
      deleteStudyCardUseCase: DeleteStudyCardUseCase(repository),
      loadDeckTagsUseCase: LoadDeckTagsUseCase(repository),
    );

    if (startImmediately) {
      bloc.add(const DeckStudyStarted());
    }

    return FakeDeckStudyBlocHarness._(repository: repository, bloc: bloc);
  }

  Future<void> dispose() => bloc.close();
}
