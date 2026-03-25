import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/screen/deck/providers/card_review.dart';
import 'package:retentio/screen/deck/card_widgets/card_side_content.dart';

import '../../helpers/card_test_samples.dart';
import '../../helpers/test_card_notifiers.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  group('CardSideContent menu', () {
    testWidgets('shows Hide, Edit Fact, and Delete entries', (tester) async {
      await setupTestEnvironment();
      addTearDown(tearDownTestEnvironment);

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: SizedBox(
              width: 420,
              height: 420,
              child: CardSideContent(isFront: true),
            ),
          ),
          overrides: [
            deckProvider.overrideWithValue(sampleDeck()),
            cardProvider.overrideWith(CardWithMenuNotifier.new),
          ],
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsWidgets);

      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();

      expect(find.text('Hide Card'), findsOneWidget);
      expect(find.text('Edit Fact'), findsOneWidget);
      expect(find.text('Delete Card'), findsOneWidget);
    });

    testWidgets('Hide card invokes nextCard with isHide true', (tester) async {
      await setupTestEnvironment();
      addTearDown(tearDownTestEnvironment);

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: SizedBox(
              width: 420,
              height: 420,
              child: CardSideContent(isFront: true),
            ),
          ),
          overrides: [
            deckProvider.overrideWithValue(sampleDeck()),
            cardProvider.overrideWith(SpyHideCardNotifier.new),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Hide Card'));
      await tester.pumpAndSettle();

      expect(SpyHideCardNotifier.active?.lastHideFlag, true);
    });

    testWidgets('Delete card confirm calls deleteCurrentCard', (tester) async {
      await setupTestEnvironment();
      addTearDown(tearDownTestEnvironment);

      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: SizedBox(
              width: 420,
              height: 420,
              child: CardSideContent(isFront: true),
            ),
          ),
          overrides: [
            deckProvider.overrideWithValue(sampleDeck()),
            cardProvider.overrideWith(CountingDeleteCardNotifier.new),
          ],
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byIcon(LucideIcons.ellipsisVertical));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Delete Card').first);
      await tester.pumpAndSettle();

      expect(find.byType(AlertDialog), findsOneWidget);

      await tester.tap(find.text('Delete Card').last);
      await tester.pumpAndSettle();

      expect(CountingDeleteCardNotifier.active?.deleteCalls, 1);
    });
  });
}
