import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:retentio/core/error/raw_api_error_message.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/review_stats.dart';
import 'package:retentio/services/apis/deck_service.dart';
import 'package:retentio/services/apis/review_stats_service.dart';

typedef LoadDecks = Future<List<Deck>> Function();
typedef LoadReviewStats =
    Future<ReviewStatsSeries> Function(String deckId, int days);

enum StatisticsStatus { loading, loaded, error }

class StatisticsState {
  const StatisticsState({
    this.decks = const [],
    this.selectedDeckId,
    this.rangeDays = 30,
    this.series,
    this.status = StatisticsStatus.loading,
    this.isRefreshing = false,
    this.error,
    this.refreshError,
  });

  final List<Deck> decks;
  final String? selectedDeckId;
  final int rangeDays;
  final ReviewStatsSeries? series;
  final StatisticsStatus status;
  final bool isRefreshing;
  final String? error;
  final String? refreshError;

  bool get hasDecks => decks.isNotEmpty;
}

class StatisticsCubit extends Cubit<StatisticsState> {
  StatisticsCubit({LoadDecks? loadDecks, LoadReviewStats? loadReviewStats})
    : _loadDecks = loadDecks ?? DeckService.of.getDecks,
      _loadReviewStats =
          loadReviewStats ??
          ((deckId, days) =>
              ReviewStatsService.of.getByDay(deckId: deckId, days: days)),
      super(const StatisticsState()) {
    loadInitial();
  }

  final LoadDecks _loadDecks;
  final LoadReviewStats _loadReviewStats;
  final Map<(String, int), ReviewStatsSeries> _cache = {};
  (String?, int)? _failedSelection;
  int _requestId = 0;

  Future<void> loadInitial() async {
    _failedSelection = null;
    final requestId = ++_requestId;
    emit(const StatisticsState());
    try {
      final decks = await _loadDecks();
      if (requestId != _requestId || isClosed) return;
      if (decks.isEmpty) {
        emit(const StatisticsState(status: StatisticsStatus.loaded, decks: []));
        return;
      }
      final series = await _loadSelection(
        decks: decks,
        selectedDeckId: null,
        days: state.rangeDays,
      );
      if (requestId != _requestId || isClosed) return;
      emit(
        StatisticsState(
          decks: decks,
          rangeDays: state.rangeDays,
          series: series,
          status: StatisticsStatus.loaded,
        ),
      );
    } catch (error) {
      if (requestId != _requestId || isClosed) return;
      emit(
        StatisticsState(
          decks: state.decks,
          rangeDays: state.rangeDays,
          status: StatisticsStatus.error,
          error: rawApiErrorMessage(error),
        ),
      );
    }
  }

  Future<void> selectDeck(String? deckId) async {
    if (deckId == state.selectedDeckId) return;
    await _loadChangedSelection(deckId: deckId, days: state.rangeDays);
  }

  Future<void> selectRange(int days) async {
    if (!ReviewStatsService.supportedRanges.contains(days)) return;
    if (days == state.rangeDays) return;
    await _loadChangedSelection(deckId: state.selectedDeckId, days: days);
  }

  Future<void> _loadChangedSelection({
    required String? deckId,
    required int days,
  }) async {
    _failedSelection = null;
    final requestId = ++_requestId;
    final current = state;
    final decks = current.decks;
    emit(
      StatisticsState(
        decks: decks,
        selectedDeckId: deckId,
        rangeDays: days,
        series: current.series,
        status: StatisticsStatus.loaded,
        isRefreshing: true,
      ),
    );
    try {
      final series = await _loadSelection(
        decks: decks,
        selectedDeckId: deckId,
        days: days,
      );
      if (requestId != _requestId || isClosed) return;
      emit(
        StatisticsState(
          decks: decks,
          selectedDeckId: deckId,
          rangeDays: days,
          series: series,
          status: StatisticsStatus.loaded,
        ),
      );
    } catch (error) {
      if (requestId != _requestId || isClosed) return;
      _failedSelection = (deckId, days);
      emit(
        StatisticsState(
          decks: decks,
          selectedDeckId: current.selectedDeckId,
          rangeDays: current.rangeDays,
          series: current.series,
          status: StatisticsStatus.loaded,
          refreshError: rawApiErrorMessage(error),
        ),
      );
    }
  }

  Future<void> retry() async {
    final failedSelection = _failedSelection;
    if (failedSelection != null) {
      await _loadChangedSelection(
        deckId: failedSelection.$1,
        days: failedSelection.$2,
      );
      return;
    }
    await refresh();
  }

  Future<void> refresh() async {
    _failedSelection = null;
    final current = state;
    final requestId = ++_requestId;
    if (current.series == null) {
      await loadInitial();
      return;
    }
    emit(
      StatisticsState(
        decks: current.decks,
        selectedDeckId: current.selectedDeckId,
        rangeDays: current.rangeDays,
        series: current.series,
        status: StatisticsStatus.loaded,
        isRefreshing: true,
      ),
    );
    try {
      final selectedIds = current.selectedDeckId == null
          ? current.decks.map((deck) => deck.id)
          : [current.selectedDeckId!];
      for (final deckId in selectedIds) {
        _cache.remove((deckId, current.rangeDays));
      }
      final series = await _loadSelection(
        decks: current.decks,
        selectedDeckId: current.selectedDeckId,
        days: current.rangeDays,
      );
      if (requestId != _requestId || isClosed) return;
      emit(
        StatisticsState(
          decks: current.decks,
          selectedDeckId: current.selectedDeckId,
          rangeDays: current.rangeDays,
          series: series,
          status: StatisticsStatus.loaded,
        ),
      );
    } catch (error) {
      if (requestId != _requestId || isClosed) return;
      emit(
        StatisticsState(
          decks: current.decks,
          selectedDeckId: current.selectedDeckId,
          rangeDays: current.rangeDays,
          series: current.series,
          status: StatisticsStatus.loaded,
          refreshError: rawApiErrorMessage(error),
        ),
      );
    }
  }

  Future<ReviewStatsSeries> _loadSelection({
    required List<Deck> decks,
    required String? selectedDeckId,
    required int days,
  }) async {
    if (selectedDeckId != null) {
      return _loadOne(selectedDeckId, days);
    }

    final results = <ReviewStatsSeries>[];
    try {
      for (var start = 0; start < decks.length; start += 4) {
        final end = (start + 4).clamp(0, decks.length);
        final batch = decks.sublist(start, end);
        results.addAll(
          await Future.wait(batch.map((deck) => _loadOne(deck.id, days))),
        );
      }
      return ReviewStatsSeries.aggregate(results);
    } catch (_) {
      // A failed aggregate is never reusable: clear the whole selection so a
      // retry cannot mix cached dates from before and after UTC midnight.
      for (final deck in decks) {
        _cache.remove((deck.id, days));
      }
      rethrow;
    }
  }

  Future<ReviewStatsSeries> _loadOne(String deckId, int days) async {
    final key = (deckId, days);
    final cached = _cache[key];
    if (cached != null) return cached;
    final series = await _loadReviewStats(deckId, days);
    _cache[key] = series;
    return series;
  }
}
