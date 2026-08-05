import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/screen/deck/bloc/deck_study_context_cubit.dart';
import 'package:retentio/screen/deck/bloc/deck_study_flip_card_controller_cubit.dart';
import 'package:retentio/screen/deck/card_widgets/card_flip.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_body.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/providers/deck_scope.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_deck_study_bloc.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  group('studyCardHeight', () {
    test('uses 62% of a tall viewport', () {
      expect(studyCardHeight(800), closeTo(496, 0.0001));
      expect(studyCardBottomSpacing(800), 100);
    });

    test('leaves room for the controls when 62% would crowd them', () {
      // 62% of 380 is 235.6, more than the 230 left after the bottom reserve.
      expect(studyCardHeight(380), closeTo(230, 0.0001));
      expect(studyCardBottomSpacing(380), 100);
    });

    test('card and spacing fit short viewports without throwing', () {
      for (final height in [330.0, 300.0, 280.0, 250.0, 200.0, 100.0, 0.0]) {
        final card = studyCardHeight(height);
        final spacing = studyCardBottomSpacing(height);
        expect(card + spacing, lessThanOrEqualTo(height), reason: 'h=$height');
        expect(() => studyCardHeight(height), returnsNormally);
      }
    });
  });

  group('DeckViewBody layout', () {
    testWidgets('card and spacing fit inside a short Expanded viewport', (
      tester,
    ) async {
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

      // Keep the LayoutBuilder viewport under 280 so the old fixed
      // 180 + 100 layout would overflow.
      const bodyHeight = 240.0;
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          MultiBlocProvider(
            providers: [
              BlocProvider(create: (_) => DeckStudyContextCubit(deck)),
              BlocProvider(create: (_) => DeckStudyFlipCardControllerCubit()),
              BlocProvider.value(value: harness.bloc),
            ],
            child: const Scaffold(
              body: SizedBox(
                height: bodyHeight,
                width: 400,
                child: DeckViewBody(),
              ),
            ),
          ),
          overrides: [
            currentDeckProvider.overrideWithValue(deck),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 200));

      final cardFinder = find.byType(CardFlip);
      expect(cardFinder, findsOneWidget);

      // Nearest LayoutBuilder ancestor is the study-card viewport.
      final layoutBuilder = find.ancestor(
        of: cardFinder,
        matching: find.byType(LayoutBuilder),
      );
      final availableHeight = tester.getSize(layoutBuilder.first).height;
      expect(availableHeight, lessThan(280));

      final card = tester.widget<CardFlip>(cardFinder);
      final spacing = studyCardBottomSpacing(availableHeight);
      expect(card.height, studyCardHeight(availableHeight));
      expect(card.height + spacing, lessThanOrEqualTo(availableHeight));
      expect(
        find.byWidgetPredicate((w) => w is SizedBox && w.height == spacing),
        findsWidgets,
      );
    });
  });
}
