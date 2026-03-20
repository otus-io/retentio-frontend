import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/learn/widgets/create_deck_widget.dart';
import 'package:retentio/widgets/number_picker.dart';

import '../../helpers/test_wrapper.dart';

void main() {
  group('CreateDeckWidget', () {
    testWidgets('rate NumberPicker is 1–1000 step 1 (create/edit deck)', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: SingleChildScrollView(child: CreateDeckWidget()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(NumberPicker), findsOneWidget);
      final picker = tester.widget<NumberPicker>(find.byType(NumberPicker));
      expect(picker.minValue, 1);
      expect(picker.maxValue, 1000);
      expect(picker.step, 1);
      expect(picker.value, 10);
    });

    testWidgets('shows name field, two field inputs, and save button', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidget(
          const Scaffold(
            body: SingleChildScrollView(child: CreateDeckWidget()),
          ),
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(TextField), findsNWidgets(3));
      expect(find.byType(FilledButton), findsOneWidget);
    });
  });
}
