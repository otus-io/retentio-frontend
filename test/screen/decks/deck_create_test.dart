import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/decks/widgets/deck_create.dart';
import 'package:retentio/widgets/number_picker.dart';

import '../../helpers/test_wrapper.dart';

void main() {
  group('DeckCreate', () {
    testWidgets('rate NumberPicker is 1–1000 step 1 (create/edit deck)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: SingleChildScrollView(child: DeckCreate())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(NumberPicker), findsOneWidget);
      final picker = tester.widget<NumberPicker>(find.byType(NumberPicker));
      expect(picker.minValue, 1);
      expect(picker.maxValue, 1000);
      expect(picker.step, 1);
      expect(picker.value, 30);
    });

    testWidgets(
      'shows name field, two default column inputs, and save button',
      (tester) async {
        await tester.pumpWidget(
          buildTestableWidget(
            const Scaffold(body: SingleChildScrollView(child: DeckCreate())),
          ),
        );
        await tester.pump();
        await tester.pump(const Duration(milliseconds: 400));

        expect(find.byType(TextField), findsNWidgets(3));
        expect(find.byType(FilledButton), findsOneWidget);
      },
    );

    testWidgets('deletes a field when its remove button is tapped', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: SingleChildScrollView(child: DeckCreate())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Initially: 1 name TextField + 2 field TextFields.
      expect(find.byType(TextField), findsNWidgets(3));

      // Add one more field so that delete is enabled.
      // Use the localized English text from deckCreateAddField.
      final addFieldButton = find.text('Add a new field');
      expect(addFieldButton, findsOneWidget);
      await tester.tap(addFieldButton);
      await tester.pumpAndSettle();

      // Now: 1 name TextField + 3 field TextFields.
      expect(find.byType(TextField), findsNWidgets(4));

      // Tap the remove button for the second field.
      final removeButtons = find.byTooltip('Remove column header');
      expect(removeButtons, findsNWidgets(3));
      await tester.tap(removeButtons.at(1));
      await tester.pumpAndSettle();

      // Back to 1 name TextField + 2 field TextFields.
      expect(find.byType(TextField), findsNWidgets(3));
    });

    testWidgets('reorders fields when dragged', (tester) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(body: SingleChildScrollView(child: DeckCreate())),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      // Enter distinct values into the two field TextFields.
      final textFields = find.byType(TextField);
      // Index 0 is the deck name; 1 and 2 are field names.
      await tester.enterText(textFields.at(1), 'First');
      await tester.enterText(textFields.at(2), 'Second');
      await tester.pump();

      // Drag the second field above the first using its drag handle.
      final handles = find.byType(ReorderableDragStartListener);
      expect(handles, findsNWidgets(2));

      final handleCenter = tester.getCenter(handles.at(1));
      final gesture = await tester.startGesture(handleCenter);
      await gesture.moveBy(const Offset(0, -80));
      await gesture.up();
      await tester.pumpAndSettle();

      final reorderedTextFields = find.byType(TextField);
      // After reordering, the first field TextField should now contain "Second".
      final firstField = tester.widget<TextField>(reorderedTextFields.at(1));
      final secondField = tester.widget<TextField>(reorderedTextFields.at(2));

      expect(firstField.controller!.text, 'Second');
      expect(secondField.controller!.text, 'First');
    });
  });
}
