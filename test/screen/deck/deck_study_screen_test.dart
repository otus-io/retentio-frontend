import 'package:flutter/material.dart';
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

    testWidgets(
      'shows current card progress instead of zero progress on first card',
      (tester) async {
        await setupTestEnvironment();
        final deck = sampleDeck(cardsCount: 5);
        final harness = FakeDeckStudyBlocHarness(
          deckId: deck.id,
          loadResults: [DeckStudyLoadResult(cardDetail: sampleCardDetail())],
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

        expect(find.text('1 / 5'), findsOneWidget);
        expect(find.text('20%'), findsOneWidget);

        final indicator = tester.widget<LinearProgressIndicator>(
          find.byType(LinearProgressIndicator),
        );
        expect(indicator.value, 0.2);
      },
    );

    testWidgets('shows a fractional percent for very small progress', (
      tester,
    ) async {
      await setupTestEnvironment();
      final deck = sampleDeck(cardsCount: 2387);
      final harness = FakeDeckStudyBlocHarness(
        deckId: deck.id,
        loadResults: [DeckStudyLoadResult(cardDetail: sampleCardDetail())],
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

      expect(find.text('1 / 2387'), findsOneWidget);
      expect(find.text('0.0%'), findsNothing);
      expect(find.text('0.04%'), findsOneWidget);

      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      expect(indicator.value, closeTo(1 / 2387, 0.000001));
    });

    testWidgets(
      'bottom action follows card side between show answer and next',
      (tester) async {
        await setupTestEnvironment();
        final deck = sampleDeck(cardsCount: 2);
        final harness = FakeDeckStudyBlocHarness(
          deckId: deck.id,
          loadResults: [
            DeckStudyLoadResult(cardDetail: sampleCardDetail()),
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

        expect(find.text('Show Answer'), findsOneWidget);
        expect(find.text('Next'), findsNothing);
        expect(find.text('Hard'), findsNothing);
        expect(find.text('Easy'), findsNothing);

        await tester.tap(find.text('Show Answer'));
        await tester.pumpAndSettle();

        expect(find.text('Show Answer'), findsNothing);
        expect(find.text('Next'), findsOneWidget);
        expect(find.text('Hard'), findsOneWidget);
        expect(find.text('Easy'), findsOneWidget);

        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('Show Answer'), findsOneWidget);
        expect(find.text('Next'), findsNothing);
        expect(find.text('Hard'), findsNothing);
        expect(find.text('Easy'), findsNothing);
      },
    );
  });
}
