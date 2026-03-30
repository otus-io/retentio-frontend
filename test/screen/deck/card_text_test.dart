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

  group('CardText (fact field text as typed in UI)', () {
    testWidgets('renders wiki ruby for markup typed into a text field', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: Center(
              child: CardText(
                text: '[[皆|みな]]さん',
                color: Colors.black,
                scrollable: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('皆'), findsOneWidget);
      expect(find.text('みな'), findsOneWidget);
      expect(find.text('さん'), findsOneWidget);
      expect(find.textContaining('[['), findsNothing);
      expect(find.byType(Wrap), findsOneWidget);
    });

    testWidgets('scrollable CardText still renders ruby with bounded height', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: SizedBox(
              height: 200,
              width: 400,
              child: CardText(
                text: '[[中国|Zhōngguó]]',
                color: Colors.black,
                scrollable: true,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('中国'), findsOneWidget);
      expect(find.text('Zhōngguó'), findsOneWidget);
      expect(find.textContaining('[['), findsNothing);
    });

    testWidgets('plain text without markup stays a single Text widget', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const Scaffold(
            body: Center(
              child: CardText(
                text: 'No ruby here',
                color: Colors.black,
                scrollable: false,
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('No ruby here'), findsOneWidget);
      expect(find.byType(Wrap), findsNothing);
    });
  });

  group('FactContent text-only (no transcript JSON)', () {
    testWidgets('text item from normal fact shows ruby same as CardText', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: SizedBox(
              height: 400,
              child: FactContent(
                color: Colors.black,
                items: [Item(type: 'text', value: '[[思|おも]]う')],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('思'), findsOneWidget);
      expect(find.text('おも'), findsOneWidget);
      expect(find.text('う'), findsOneWidget);
      expect(find.textContaining('[['), findsNothing);
    });

    testWidgets('multiple text items each render ruby independently', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          Scaffold(
            body: SizedBox(
              height: 400,
              child: FactContent(
                color: Colors.blue,
                items: [
                  Item(type: 'text', value: '[[甲|jiǎ]]'),
                  Item(type: 'text', value: '[[乙|yǐ]]'),
                ],
              ),
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('甲'), findsOneWidget);
      expect(find.text('jiǎ'), findsOneWidget);
      expect(find.text('乙'), findsOneWidget);
      expect(find.text('yǐ'), findsOneWidget);
    });
  });
}
