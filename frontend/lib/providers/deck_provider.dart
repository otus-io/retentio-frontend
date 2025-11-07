import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/deck.dart';
import '../services/deck_service.dart';

/// Deck 列表状态
class DeckListState {
  final List<Deck> decks;
  final bool isLoading;
  final String? error;

  DeckListState({this.decks = const [], this.isLoading = false, this.error});

  DeckListState copyWith({List<Deck>? decks, bool? isLoading, String? error}) {
    return DeckListState(
      decks: decks ?? this.decks,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

/// Deck 列表 Notifier
class DeckListNotifier extends StateNotifier<DeckListState> {
  DeckListNotifier() : super(DeckListState());

  /// 加载 decks
  Future<void> loadDecks() async {
    state = state.copyWith(isLoading: true, error: null);

    try {
      final decks = await DeckService.getDecks();
      state = state.copyWith(decks: decks, isLoading: false);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }

  /// 刷新 decks
  Future<void> refresh() async {
    await loadDecks();
  }
}

/// Deck 列表 Provider
final deckListProvider = StateNotifierProvider<DeckListNotifier, DeckListState>(
  (ref) => DeckListNotifier(),
);
