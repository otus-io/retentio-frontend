import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/features/deck_study/domain/repositories/deck_study_repository.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/card_widgets/card_side_content.dart';
import 'package:retentio/screen/deck/deck_widgets/deck_view_interval_slider_controls.dart';
import 'package:retentio/screen/deck/providers/deck_scope.dart';
import 'package:retentio/widgets/buttons_tab_bar.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/fake_deck_study_bloc.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  group('CardSideContent stacked back layout', () {
    Future<FakeDeckStudyBlocHarness> pumpCardSide(
      WidgetTester tester, {
      required bool isFront,
      CardDetail? cardDetail,
    }) async {
      await setupTestEnvironment();
      final harness = FakeDeckStudyBlocHarness(
        deckId: sampleDeck().id,
        loadResults: [
          DeckStudyLoadResult(
            cardDetail: cardDetail ?? sampleMultiFieldCardDetail(),
          ),
        ],
      );
      addTearDown(() async {
        await harness.dispose();
        tearDownTestEnvironment();
      });

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: SizedBox(
              width: 420,
              height: 520,
              child: CardSideContent(isFront: isFront),
            ),
          ),
          overrides: [
            currentDeckProvider.overrideWithValue(sampleDeck()),
            deckStudyBlocProvider.overrideWithValue(harness.bloc),
          ],
        ),
      );
      await tester.pumpAndSettle();
      return harness;
    }

    testWidgets('back shows all field sections without field tab bar', (
      tester,
    ) async {
      await pumpCardSide(tester, isFront: false);

      expect(find.text('利益, 好处 ; 优势'), findsOneWidget);
      expect(
        find.text('The discovery of oil brought many benefits to the town.'),
        findsOneWidget,
      );
      expect(find.text('石油的发现给该镇带来很多利益。'), findsOneWidget);

      expect(find.text('CHINESE'), findsOneWidget);
      expect(find.text('ENGLISH EXAMPLE'), findsOneWidget);
      expect(find.text('CHINESE EXAMPLE'), findsOneWidget);

      expect(find.byType(ButtonsTabBar), findsNothing);
    });

    testWidgets('front keeps field tab bar for multi-field cards', (
      tester,
    ) async {
      await pumpCardSide(tester, isFront: true);

      expect(find.text('Word'), findsOneWidget);
      expect(find.text('Reading'), findsOneWidget);
      expect(find.text('benefit'), findsOneWidget);
      expect(find.text('ˈbenɪfɪt'), findsNothing);
    });

    testWidgets('back inline text is left-aligned', (tester) async {
      await pumpCardSide(tester, isFront: false);

      final definition = tester.widget<Text>(find.text('利益, 好处 ; 优势'));
      expect(definition.textAlign, TextAlign.start);
    });

    testWidgets(
      'back uses tabbed FactContent without field labels for single-field cards',
      (tester) async {
        await pumpCardSide(
          tester,
          isFront: false,
          cardDetail: sampleCardDetail(),
        );

        expect(find.text('World'), findsOneWidget);
        expect(find.text('BACK'), findsNothing);

        final backText = tester.widget<Text>(find.text('World'));
        expect(backText.textAlign, TextAlign.center);

        // Media tab bar from FactContent, not field tabs (multi-field back has none).
        expect(find.byType(ButtonsTabBar), findsOneWidget);
      },
    );
  });
}
