import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/features/deck_study/domain/usecases/delete_study_card_usecase.dart';
import 'package:retentio/features/deck_study/domain/usecases/get_next_due_card_usecase.dart';
import 'package:retentio/features/deck_study/domain/usecases/submit_card_review_usecase.dart';
import 'package:retentio/features/deck_study/domain/value_objects/review_interval_range.dart';
import 'package:retentio/features/deck_study/presentation/bloc/deck_study_event.dart';
import 'package:retentio/features/deck_study/presentation/bloc/deck_study_state.dart';

class DeckStudyBloc extends Cubit<DeckStudyState> {
  DeckStudyBloc({
    required String deckId,
    required GetNextDueCardUseCase getNextDueCardUseCase,
    required SubmitCardReviewUseCase submitCardReviewUseCase,
    required DeleteStudyCardUseCase deleteStudyCardUseCase,
  }) : _getNextDueCardUseCase = getNextDueCardUseCase,
       _submitCardReviewUseCase = submitCardReviewUseCase,
       _deleteStudyCardUseCase = deleteStudyCardUseCase,
       super(DeckStudyState(deckId: deckId)) {
    _eventSubscription = _eventController.stream
        .asyncMap(_onEvent)
        .listen(null);
  }

  final GetNextDueCardUseCase _getNextDueCardUseCase;
  final SubmitCardReviewUseCase _submitCardReviewUseCase;
  final DeleteStudyCardUseCase _deleteStudyCardUseCase;

  final StreamController<DeckStudyEvent> _eventController =
      StreamController<DeckStudyEvent>();
  late final StreamSubscription<void> _eventSubscription;

  bool _isClosed = false;

  void add(DeckStudyEvent event) {
    if (_isClosed) {
      return;
    }
    _eventController.add(event);
  }

  Future<void> _onEvent(DeckStudyEvent event) async {
    if (event is DeckStudyStarted) {
      await _loadCard(resetProgress: false);
      return;
    }
    if (event is DeckStudyShowAnswerRequested) {
      _emit(
        state.copyWith(
          showAnswer: true,
          loadingPhase: DeckStudyLoadingPhase.loaded,
        ),
      );
      return;
    }
    if (event is DeckStudyShowAnswerToggled) {
      _emit(
        state.copyWith(
          showAnswer: !state.showAnswer,
          loadingPhase: DeckStudyLoadingPhase.loaded,
        ),
      );
      return;
    }
    if (event is DeckStudyIntervalSelected) {
      _emit(state.copyWith(selectedInterval: event.intervalSeconds));
      return;
    }
    if (event is DeckStudyReviewAgainRequested) {
      _emit(
        state.copyWith(
          loadingPhase: DeckStudyLoadingPhase.initial,
          isHide: false,
          showAnswer: true,
          cardsStudied: 0,
          isLoading: true,
          resetCardDetail: true,
          clearRefreshedCardsCount: true,
        ),
      );
      await _loadCard(resetProgress: false);
      return;
    }
    if (event is DeckStudyReloadRequested) {
      await _loadCard(resetProgress: false);
      return;
    }
    if (event is DeckStudyNextCardRequested) {
      await _handleNextCard(event.hideCurrentCard);
      return;
    }
    if (event is DeckStudyDeleteCurrentCardRequested) {
      await _handleDeleteCurrentCard();
    }
  }

  Future<void> _handleNextCard(bool hideCurrentCard) async {
    final cardId = state.cardDetail?.card.id;
    if (cardId == null || cardId.isEmpty) {
      await _loadCard(resetProgress: false);
      return;
    }

    _emit(
      state.copyWith(
        loadingPhase: DeckStudyLoadingPhase.initial,
        isHide: hideCurrentCard,
        clearErrorMessage: true,
      ),
    );

    final deckId = state.deckId;
    final success = hideCurrentCard
        ? await _submitCardReviewUseCase.hide(deckId: deckId, cardId: cardId)
        : await _submitCardReviewUseCase.review(
            deckId: deckId,
            cardId: cardId,
            intervalSeconds: state.selectedInterval.round(),
            lastReviewSeconds: DateTime.now().millisecondsSinceEpoch ~/ 1000,
          );

    if (!success) {
      _emit(
        state.copyWith(
          loadingPhase: DeckStudyLoadingPhase.error,
          errorMessage: 'Failed to submit current card.',
        ),
      );
      return;
    }

    await _loadCard(
      resetProgress: false,
      cardsStudiedOverride: state.cardsStudied + 1,
    );
  }

  Future<void> _handleDeleteCurrentCard() async {
    final cardId = state.cardDetail?.card.id;
    if (cardId == null || cardId.isEmpty) {
      return;
    }

    final success = await _deleteStudyCardUseCase(
      deckId: state.deckId,
      cardId: cardId,
    );
    if (!success) {
      _emit(
        state.copyWith(
          loadingPhase: DeckStudyLoadingPhase.error,
          errorMessage: 'Failed to delete current card.',
        ),
      );
      return;
    }

    await _loadCard(resetProgress: false);
    _emit(state.copyWith(showAnswer: true));
  }

  Future<void> _loadCard({
    required bool resetProgress,
    int? cardsStudiedOverride,
  }) async {
    _emit(
      state.copyWith(
        isLoading: true,
        loadingPhase: DeckStudyLoadingPhase.loading,
        cardsStudied:
            cardsStudiedOverride ?? (resetProgress ? 0 : state.cardsStudied),
        clearErrorMessage: true,
      ),
    );

    final result = await _getNextDueCardUseCase(deckId: state.deckId);
    final detail = result.cardDetail;

    if (detail != null) {
      final nowSec = DateTime.now().toUtc().millisecondsSinceEpoch ~/ 1000;
      final interval = ReviewIntervalRange.fromTimestamps(
        nowSec: nowSec,
        lastReview: detail.card.lastReview,
        dueDate: detail.card.dueDate,
      );
      _emit(
        state.copyWith(
          cardDetail: detail,
          isLoading: false,
          isHide: false,
          loadingPhase: DeckStudyLoadingPhase.loaded,
          clearRefreshedCardsCount: true,
          minInterval: interval.minInterval,
          maxInterval: interval.maxInterval,
          selectedInterval: interval.midInterval,
        ),
      );
      return;
    }

    _emit(
      state.copyWith(
        resetCardDetail: true,
        isLoading: false,
        isHide: false,
        loadingPhase: DeckStudyLoadingPhase.loaded,
        refreshedCardsCount: result.refreshedCardsCount,
        minInterval: 0,
        maxInterval: 0,
        selectedInterval: 0,
      ),
    );
  }

  void _emit(DeckStudyState nextState) {
    if (_isClosed) {
      return;
    }
    emit(nextState);
  }

  @override
  Future<void> close() async {
    if (_isClosed) {
      return;
    }
    _isClosed = true;
    await _eventSubscription.cancel();
    await _eventController.close();
    await super.close();
  }
}
