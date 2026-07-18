import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/card.dart';
import 'package:retentio/screen/deck/card_widgets/card_text.dart';
import 'package:retentio/screen/deck/fact_widgets/fact_content.dart';

import '../../helpers/test_wrapper.dart';

void main() {
  setUpAll(() async {
    await setupTestEnvironment();
  });
  tearDownAll(tearDownTestEnvironment);

  group('FactContent inline mode', () {
    testWidgets('inline: true renders a Column with no TabBarView', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: FactContent(
              inline: true,
              color: Colors.black,
              items: [Item(type: 'text', value: 'Hello')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Hello'), findsOneWidget);
      expect(find.byType(TabBarView), findsNothing);
    });

    testWidgets('inline: false (default) uses TabBarView', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: SizedBox(
              height: 400,
              child: FactContent(
                color: Colors.black,
                items: [Item(type: 'text', value: 'Hello')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TabBarView), findsOneWidget);
    });

    testWidgets('inline: true with no items renders empty CardText', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: FactContent(inline: true, color: Colors.black, items: []),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(CardText), findsOneWidget);
      expect(find.byType(TabBarView), findsNothing);
    });

    testWidgets('inline: true with whitespace-only item renders no text', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: FactContent(
              inline: true,
              color: Colors.black,
              items: [Item(type: 'text', value: '   ')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // whitespace item is in textLikeItems so _InlineTextPane is rendered,
      // but it filters the item out → empty Column, no CardText shown
      expect(find.byType(CardText), findsNothing);
    });

    testWidgets('_InlineTextPane: single item has bottom padding 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: FactContent(
              inline: true,
              color: Colors.black,
              items: [Item(type: 'text', value: 'Only item')],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // The single CardText is wrapped in a Padding; bottom should be 0
      final padding = tester.widget<Padding>(
        find
            .ancestor(of: find.byType(CardText), matching: find.byType(Padding))
            .first,
      );
      expect(padding.padding.resolve(TextDirection.ltr).bottom, 0.0);
    });

    testWidgets('_InlineTextPane: last of multiple items has bottom padding 0', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: FactContent(
              inline: true,
              color: Colors.black,
              items: [
                Item(type: 'text', value: 'First'),
                Item(type: 'text', value: 'Second'),
                Item(type: 'text', value: 'Third'),
              ],
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      // Find all Padding ancestors of CardText widgets
      final cardTextFinder = find.byType(CardText);
      expect(cardTextFinder, findsNWidgets(3));

      final paddings = tester
          .widgetList<Padding>(
            find.ancestor(of: cardTextFinder, matching: find.byType(Padding)),
          )
          .toList();

      // Inner-most Padding for each CardText (first ancestor match)
      // paddings may have multiple entries per CardText; we want the direct parent
      final bottomValues = paddings
          .map((p) => p.padding.resolve(TextDirection.ltr).bottom)
          .toList();

      // Last padding's bottom must be 0; non-last must be 8
      expect(bottomValues.last, 0.0);
      expect(bottomValues.first, 8.0);
    });
  });
}
