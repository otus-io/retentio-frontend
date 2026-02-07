import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../mixins/refresh_controller_mixin.dart';
import '../models/deck.dart';
import '../services/apis/deck_service.dart';

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
class DeckListNotifier extends Notifier<DeckListState> with RefreshControllerMixin{
  @override
  DeckListState build() {
    refreshBuild();
    return DeckListState(isLoading: true);
  }

  /// 加载 decks
  Future<void> loadDecks() async {
    try {
      final decks = await DeckService.getDecks();
      state = state.copyWith( isLoading: false,decks: decks);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: e.toString());
    }
  }


  @override
  Future<List<dynamic>?> loadData() async{
    await loadDecks();
    return state.decks;
  }
}

/// Deck 列表 Provider
final deckListProvider = NotifierProvider<DeckListNotifier, DeckListState>(
  DeckListNotifier.new,
);
