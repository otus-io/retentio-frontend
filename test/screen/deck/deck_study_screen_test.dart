import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/deck_view_screen.dart';
import 'package:retentio/screen/deck/providers/card_provider.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/immediate_empty_card_notifier.dart';
import '../../helpers/test_card_notifiers.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  final emptySessionDeck = Deck.fromJson({
    'id': 'deck-study-1',
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

  group('DeckViewScreen', () {
    testWidgets('shows empty deck message when session has no cards', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          DeckViewScreen(deck: emptySessionDeck),
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

    testWidgets('Review Again calls getCardDetail on notifier', (tester) async {
      await setupTestEnvironment();
      addTearDown(tearDownTestEnvironment);

      final deck = sampleDeck(cardsCount: 5);

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          DeckViewScreen(deck: deck),
          overrides: [
            deckProvider.overrideWithValue(deck),
            cardProvider.overrideWith(
              () => ReviewAgainHarnessNotifier(deckCardCount: 5),
            ),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Review Again'), findsOneWidget);
      await tester.tap(find.text('Review Again'));
      await tester.pumpAndSettle();

      expect(ReviewAgainHarnessNotifier.active?.getCardDetailCalls, 1);
    });
  });
}
