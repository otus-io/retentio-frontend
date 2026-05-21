import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/services/apis/deck_service.dart';

class DeckListState {
  const DeckListState({
    this.decks = const <Deck>[],
    this.isLoading = true,
    this.error,
  });

  final List<Deck> decks;
  final bool isLoading;
  final String? error;

  DeckListState copyWith({
    List<Deck>? decks,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return DeckListState(
      decks: decks ?? this.decks,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
    );
  }
}

class DeckListCubit extends Cubit<DeckListState> {
  DeckListCubit() : super(const DeckListState()) {
    onRefresh();
  }

  final RefreshController refreshController = RefreshController();

  static const int _pageSize = 20;

  bool _disposed = false;
  bool _noMore = false;

  @override
  Future<void> close() {
    _disposed = true;
    return super.close();
  }

  Future<void> loadDecks() async {
    emit(state.copyWith(isLoading: true, clearError: true));
    try {
      final decks = await DeckService.of.getDecks();
      emit(state.copyWith(decks: decks, isLoading: false, clearError: true));
    } catch (e) {
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> deleteDeck(Deck deck) async {
    await DeckService.of.deleteDeck(deck.id);
    await onRefresh();
  }

  void _safe(void Function() action) {
    try {
      action();
    } catch (_) {
      // pull_to_refresh may throw when load channel is unavailable.
    }
  }

  Future<void> onRefresh() async {
    if (refreshController.isLoading) {
      _safe(refreshController.refreshCompleted);
      return;
    }
    try {
      final decks = await DeckService.of.getDecks();
      _safe(refreshController.refreshCompleted);
      if (decks.length < _pageSize) {
        _noMore = true;
        _safe(refreshController.loadNoData);
      } else {
        _noMore = false;
        _safe(refreshController.resetNoData);
      }
      if (_disposed) {
        return;
      }
      emit(state.copyWith(decks: decks, isLoading: false, clearError: true));
    } catch (e) {
      _safe(refreshController.refreshFailed);
      if (_disposed) {
        return;
      }
      emit(state.copyWith(isLoading: false, error: e.toString()));
    }
  }

  Future<void> onLoading() async {
    if (refreshController.isRefresh) {
      _safe(refreshController.loadComplete);
      return;
    }
    if (_noMore) {
      _safe(refreshController.loadNoData);
      return;
    }
    // current API is non-paginated, so treat pull-up as completed.
    _safe(refreshController.loadNoData);
    _noMore = true;
  }
}
