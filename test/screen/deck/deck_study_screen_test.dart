import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/models/tag.dart';
import 'package:retentio/screen/deck/deck_view_screen.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_study_tag_filter_bar.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/providers/deck_scope.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_deck_study_bloc.dart';
import '../../helpers/test_wrapper.dart';

Future<void> _selectStudyTagFilter(WidgetTester tester, String tagName) async {
  await tester.tap(find.byKey(const Key('deck_study_tag_filter')));
  await tester.pumpAndSettle();
  await tester.tap(
    find.descendant(of: find.byType(BottomSheet), matching: find.text(tagName)),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets(
    'all chip is not selected when activeTagId is missing in tags list',
    (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          Scaffold(
            body: DeckStudyTagFilterBar(
              tags: const [Tag(id: 'tag-1', name: 'Grammar', description: '')],
              activeTagId: 'tag-missing',
              onTagSelected: (_) {},
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      final chip = tester.widget<ChoiceChip>(
        find.widgetWithText(ChoiceChip, 'All'),
      );
      expect(chip.selected, isFalse);
    },
  );

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

    testWidgets('shows empty tag filter message instead of all caught up', (
      tester,
    ) async {
      await setupTestEnvironment();
      final deck = sampleDeck(cardsCount: 5);
      const grammarTag = Tag(id: 'tag1', name: 'Grammar', description: '');
      final harness = FakeDeckStudyBlocHarness(
        deckId: deck.id,
        deckTags: const [grammarTag],
        loadResults: [
          DeckStudyLoadResult(cardDetail: sampleCardDetail()),
          const DeckStudyLoadResult(cardDetail: null),
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

      await _selectStudyTagFilter(tester, 'Grammar');
      await tester.pumpAndSettle();

      expect(find.text('No cards with tag "Grammar"'), findsOneWidget);
      expect(find.text('All Caught Up!'), findsNothing);
      expect(find.text('Clear filter'), findsOneWidget);
    });

    testWidgets('dismissing tag filter sheet keeps current selection', (
      tester,
    ) async {
      await setupTestEnvironment();
      final deck = sampleDeck(cardsCount: 5);
      const grammarTag = Tag(id: 'tag1', name: 'Grammar', description: '');
      final harness = FakeDeckStudyBlocHarness(
        deckId: deck.id,
        deckTags: const [grammarTag],
        loadResults: [
          DeckStudyLoadResult(cardDetail: sampleCardDetail()),
          const DeckStudyLoadResult(cardDetail: null),
          const DeckStudyLoadResult(cardDetail: null),
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

      await _selectStudyTagFilter(tester, 'Grammar');
      await tester.pumpAndSettle();
      final loadsAfterSelect = harness.repository.loadCalls;

      await tester.tap(find.byKey(const Key('deck_study_tag_filter')));
      await tester.pumpAndSettle();
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(harness.repository.loadCalls, loadsAfterSelect);
      expect(find.text('No cards with tag "Grammar"'), findsOneWidget);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'Grammar'))
            .selected,
        isTrue,
      );
    });

    testWidgets('selecting All in tag filter sheet clears active filter', (
      tester,
    ) async {
      await setupTestEnvironment();
      final deck = sampleDeck(cardsCount: 5);
      const grammarTag = Tag(id: 'tag1', name: 'Grammar', description: '');
      final harness = FakeDeckStudyBlocHarness(
        deckId: deck.id,
        deckTags: const [grammarTag],
        loadResults: [
          DeckStudyLoadResult(cardDetail: sampleCardDetail()),
          const DeckStudyLoadResult(cardDetail: null),
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

      await _selectStudyTagFilter(tester, 'Grammar');
      await tester.pumpAndSettle();
      expect(find.text('No cards with tag "Grammar"'), findsOneWidget);

      await tester.tap(find.byKey(const Key('deck_study_tag_filter')));
      await tester.pumpAndSettle();
      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('All'),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.repository.loadTagIds, [null, 'tag1', null]);
      expect(find.text('No cards with tag "Grammar"'), findsNothing);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All'))
            .selected,
        isTrue,
      );
    });

    testWidgets('selecting All still works when search has no matches', (
      tester,
    ) async {
      await setupTestEnvironment();
      final deck = sampleDeck(cardsCount: 5);
      const grammarTag = Tag(id: 'tag1', name: 'Grammar', description: '');
      final harness = FakeDeckStudyBlocHarness(
        deckId: deck.id,
        deckTags: const [grammarTag],
        loadResults: [
          DeckStudyLoadResult(cardDetail: sampleCardDetail()),
          const DeckStudyLoadResult(cardDetail: null),
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

      await _selectStudyTagFilter(tester, 'Grammar');
      await tester.pumpAndSettle();

      await tester.tap(find.byKey(const Key('deck_study_tag_filter')));
      await tester.pumpAndSettle();
      await tester.enterText(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.byType(TextField),
        ),
        'zzz-no-match',
      );
      await tester.pumpAndSettle();

      await tester.tap(
        find.descendant(
          of: find.byType(BottomSheet),
          matching: find.text('All'),
        ),
      );
      await tester.pumpAndSettle();

      expect(harness.repository.loadTagIds, [null, 'tag1', null]);
      expect(
        tester
            .widget<ChoiceChip>(find.widgetWithText(ChoiceChip, 'All'))
            .selected,
        isTrue,
      );
    });

    testWidgets('shows due count and clearing progress bar', (tester) async {
      await setupTestEnvironment();
      final deck = sampleDeck(cardsCount: 5);
      final harness = FakeDeckStudyBlocHarness(
        deckId: deck.id,
        loadResults: [
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(),
            refreshedDueCardsCount: 5,
          ),
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

      expect(find.text('0 / 5'), findsOneWidget);
      final indicator = tester.widget<LinearProgressIndicator>(
        find.byType(LinearProgressIndicator),
      );
      // At session start, live due == target → 0% cleared.
      expect(indicator.value, 0.0);
    });

    testWidgets(
      'due progress bar fills as live due drops toward frozen target',
      (tester) async {
        await setupTestEnvironment();
        final deck = sampleDeck(cardsCount: 10);
        final harness = FakeDeckStudyBlocHarness(
          deckId: deck.id,
          loadResults: [
            DeckStudyLoadResult(
              cardDetail: sampleCardDetail(),
              refreshedDueCardsCount: 4,
            ),
            DeckStudyLoadResult(
              cardDetail: sampleCardDetail(),
              refreshedDueCardsCount: 1,
            ),
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

        expect(find.text('0 / 4'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          0.0,
        );

        await tester.tap(find.text('Show Answer'));
        await tester.pumpAndSettle();
        await tester.tap(find.text('Next'));
        await tester.pumpAndSettle();

        expect(find.text('3 / 4'), findsOneWidget);
        expect(
          tester
              .widget<LinearProgressIndicator>(
                find.byType(LinearProgressIndicator),
              )
              .value,
          closeTo(0.75, 0.000001),
        );
      },
    );

    testWidgets('uses tag-scoped live due for progress when filter is active', (
      tester,
    ) async {
      await setupTestEnvironment();
      final deck = sampleDeck(cardsCount: 2387);
      const grammarTag = Tag(id: 'tag1', name: 'Grammar', description: '');
      final harness = FakeDeckStudyBlocHarness(
        deckId: deck.id,
        deckTags: const [grammarTag],
        loadResults: [
          const DeckStudyLoadResult(
            cardDetail: null,
            refreshedCardsCount: 12,
            refreshedDueCardsCount: 3,
          ),
          DeckStudyLoadResult(
            cardDetail: sampleCardDetail(),
            refreshedCardsCount: 12,
            refreshedDueCardsCount: 3,
          ),
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

      await _selectStudyTagFilter(tester, 'Grammar');
      await tester.pumpAndSettle();

      expect(find.text('0 / 3'), findsOneWidget);
      expect(find.text('0 / 2387'), findsNothing);
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
