import 'package:pull_to_refresh/pull_to_refresh.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/providers/deck_provider.dart';

/// [DeckListNotifier] that shows static decks without initial [onRefresh] (tests).
class FakeDeckListNotifier extends DeckListNotifier {
  FakeDeckListNotifier(this._decks);

  final List<Deck> _decks;

  @override
  DeckListState build() {
    refreshController = RefreshController(initialRefresh: false);
    ref.onDispose(() {
      refreshController.dispose();
    });
    return DeckListState(isLoading: false, decks: _decks);
  }

  @override
  Future<void> loadDecks() async {
    state = state.copyWith(isLoading: false, decks: _decks);
  }
}
