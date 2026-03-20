import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/deck_learn_screen.dart';
import 'package:retentio/screen/deck/providers/card_provider.dart';

import '../../helpers/immediate_empty_card_notifier.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  final emptySessionDeck = Deck.fromJson({
    'id': 'deck-learn-1',
    'name': 'Empty session',
    'stats': {
      'cards_count': 0,
      'unseen_cards': 0,
      'due_cards': 0,
      'facts_count': 0,
    },
    'rate': 10,
    'owner': {'username': 'u', 'email': 'u@t.com'},
    'fields': ['a', 'b'],
  });

  group('DeckLearnScreen', () {
    testWidgets('shows empty deck message when session has no cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          DeckLearnScreen(deck: emptySessionDeck),
          overrides: [
            deckProvider.overrideWithValue(emptySessionDeck),
            cardProvider.overrideWith(ImmediateEmptyCardNotifier.new),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No cards in this deck'), findsOneWidget);
    });
  });
}
