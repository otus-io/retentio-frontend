import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/features/deck_study/presentation/bloc/deck_study_bloc.dart';
import 'package:retentio/features/tags/tag_manager_cubit.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/deck/card_widgets/card_side_content.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_edit.dart';
import 'package:retentio/screen/deck/providers/deck_scope.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_deck_study_bloc.dart';
import '../../helpers/fake_fact_api_interceptor.dart';
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

    testWidgets('Delete card confirm calls delete on repository', (
      tester,
    ) async {
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

    Future<FakeDeckStudyBlocHarness> pumpMenu(
      WidgetTester tester,
      Deck deck,
    ) async {
      await setupTestEnvironment();
      final interceptor = attachFakeFactApiInterceptor();
      final harness = FakeDeckStudyBlocHarness(
        deckId: deck.id,
        loadResults: [DeckStudyLoadResult(cardDetail: sampleCardDetail())],
      );
      addTearDown(() async {
        detachFakeFactApiInterceptor(interceptor);
        await harness.dispose();
        tearDownTestEnvironment();
      });
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          BlocProvider<DeckStudyBloc>.value(
            value: harness.bloc,
            child: const Scaffold(
              body: SizedBox(
                width: 420,
                height: 420,
                child: CardSideContent(isFront: true),
              ),
            ),
          ),
          overrides: [
            currentDeckProvider.overrideWithValue(deck),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
        ),
      );
      await tester.pumpAndSettle();
      await tester.tap(find.byIcon(LucideIcons.ellipsis));
      await tester.pumpAndSettle();
      return harness;
    }

    Future<void> expectFactEditOpen(WidgetTester tester) async {
      expect(find.byType(FactEdit), findsOneWidget);
      final tags = tester
          .element(find.byType(FactEdit))
          .read<TagManagerCubit>();
      expect(tags.deckId, isNotEmpty);
      await tester.pumpAndSettle();
    }

    testWidgets('Edit Fact opens the fact editor', (tester) async {
      final harness = await pumpMenu(tester, sampleDeck());
      await tester.tap(find.text('Edit Fact'));
      await tester.pumpAndSettle();
      await expectFactEditOpen(tester);
      final loadsBefore = harness.repository.loadCalls;
      final saved = tester.widget<FactEdit>(find.byType(FactEdit)).onSaved();
      await tester.pumpAndSettle();
      await saved;
      expect(harness.repository.loadCalls, greaterThan(loadsBefore));
    });

    testWidgets('Report issue > Fix it yourself opens the fact editor', (
      tester,
    ) async {
      await pumpMenu(tester, sampleDeck(sourceDeckId: 'src-1'));
      await tester.tap(find.text('Report issue'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Fix it yourself'));
      await tester.pumpAndSettle();
      await expectFactEditOpen(tester);
    });
  });
}
