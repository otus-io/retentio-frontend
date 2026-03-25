import 'package:retentio/screen/deck/providers/card_provider.dart';

/// Skips network; ends in a non-loading state for empty-session deck UI tests.
class ImmediateEmptyCardNotifier extends CardNotifier {
  @override
  CardState build() {
    deck = ref.watch(deckProvider);
    ref.onDispose(flipCardController.dispose);
    return CardState(isLoading: false, showAnswer: false);
  }
}
