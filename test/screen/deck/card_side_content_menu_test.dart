import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/screen/deck/card_widgets/card_side_content.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/providers/deck_scope.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_deck_study_bloc.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  group('CardSideContent menu', () {
    testWidgets('shows Hide, Edit Fact, and Delete entries', (tester) async {
      await setupTestEnvironment();
      final harness = FakeDeckStudyBlocHarness(
        deckId: sampleDeck().id,
        loadResults: [DeckStudyLoadResult(cardDetail: sampleCardDetail())],
      );
      addTearDown(() async {
        await harness.dispose();
        tearDownTestEnvironment();
      });

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: SizedBox(
              width: 420,
              height: 420,
              child: CardSideContent(isFront: true),
            ),
          ),
          overrides: [
            currentDeckProvider.overrideWithValue(sampleDeck()),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsWidgets);

      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();

      expect(find.text('Hide Card'), findsOneWidget);
      expect(find.text('Edit Fact'), findsOneWidget);
      expect(find.text('Delete Card'), findsOneWidget);
    });

    testWidgets('Hide card invokes hide submit path', (tester) async {
      await setupTestEnvironment();
      final harness = FakeDeckStudyBlocHarness(
        deckId: sampleDeck().id,
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
          const Scaffold(
            body: SizedBox(
              width: 420,
              height: 420,
              child: CardSideContent(isFront: true),
            ),
          ),
          overrides: [
            currentDeckProvider.overrideWithValue(sampleDeck()),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide Card'));
      await tester.pumpAndSettle();

      expect(harness.repository.hideSubmitCalls, 1);
    });

    testWidgets('Delete card confirm calls delete on repository', (tester) async {
      await setupTestEnvironment();
      final harness = FakeDeckStudyBlocHarness(
        deckId: sampleDeck().id,
        loadResults: [
          DeckStudyLoadResult(cardDetail: sampleCardDetail()),
          const DeckStudyLoadResult(cardDetail: null, refreshedCardsCount: 0),
        ],
      );
      addTearDown(() async {
        await harness.dispose();
        tearDownTestEnvironment();
      });

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: SizedBox(
              width: 420,
              height: 420,
              child: CardSideContent(isFront: true),
            ),
          ),
          overrides: [
            currentDeckProvider.overrideWithValue(sampleDeck()),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Card').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Delete Card').last);
      await tester.pumpAndSettle();

      expect(harness.repository.deleteCalls, 1);
    });
  });
}
