import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/deck_view_screen.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/providers/deck_scope.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_deck_study_bloc.dart';
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
      await setupTestEnvironment();
      final harness = FakeDeckStudyBlocHarness(
        deckId: emptySessionDeck.id,
        loadResults: const [DeckStudyLoadResult(cardDetail: null)],
      );
      addTearDown(() async {
        await harness.dispose();
        tearDownTestEnvironment();
      });

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          DeckViewScreen(deck: emptySessionDeck),
          overrides: [
            currentDeckProvider.overrideWithValue(emptySessionDeck),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      expect(find.text('No cards in this deck'), findsOneWidget);
    });

    testWidgets('Review Again triggers one more card reload', (tester) async {
      await setupTestEnvironment();
      final deck = sampleDeck(cardsCount: 5);
      final harness = FakeDeckStudyBlocHarness(
        deckId: deck.id,
        loadResults: [
          const DeckStudyLoadResult(cardDetail: null, refreshedCardsCount: 5),
          DeckStudyLoadResult(cardDetail: sampleCardDetail()),
        ],
      );
      addTearDown(() async {
        await harness.dispose();
        tearDownTestEnvironment();
      });

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          DeckViewScreen(deck: deck),
          overrides: [
            currentDeckProvider.overrideWithValue(deck),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
        ),
      );
      await tester.pumpAndSettle();

      final before = harness.repository.loadCalls;
      expect(find.text('Review Again'), findsOneWidget);
      await tester.tap(find.text('Review Again'));
      await tester.pumpAndSettle();

      expect(harness.repository.loadCalls, before + 1);
    });
  });
}
