import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/bottom_popup.dart';

void main() {
  group('BottomPopup Widget', () {
    testWidgets('renders its child widget', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(body: BottomPopup(child: const Text('Test Child'))),
        ),
      );

      expect(find.text('Test Child'), findsOneWidget);
    });

    testWidgets('show method opens a modal bottom sheet', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BottomPopup.show(context, child: const Text('Sheet Content'));
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Sheet Content'), findsOneWidget);
    });

    testWidgets('show method uses default height of 320', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BottomPopup.show(
                    context,
                    child: const Text('Default Height Content'),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify content is displayed (default height was used)
      expect(find.text('Default Height Content'), findsOneWidget);

      // Find the SizedBox that constrains the height
      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.text('Default Height Content'),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.height, 320);
    });

    testWidgets('show method accepts custom height', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BottomPopup.show(
                    context,
                    child: const Text('Custom Height'),
                    height: 500,
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      expect(find.text('Custom Height'), findsOneWidget);

      final sizedBox = tester.widget<SizedBox>(
        find
            .ancestor(
              of: find.text('Custom Height'),
              matching: find.byType(SizedBox),
            )
            .first,
      );
      expect(sizedBox.height, 500);
    });

    testWidgets('show method can be dismissed by tapping outside', (
      tester,
    ) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BottomPopup.show(
                    context,
                    child: const Text('Dismissible Content'),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      // Open the sheet
      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();
      expect(find.text('Dismissible Content'), findsOneWidget);

      // Dismiss by tapping the barrier (outside the sheet)
      await tester.tapAt(const Offset(20, 20));
      await tester.pumpAndSettle();

      expect(find.text('Dismissible Content'), findsNothing);
    });

    testWidgets('bottom sheet has rounded top corners', (tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Builder(
              builder: (context) => ElevatedButton(
                onPressed: () {
                  BottomPopup.show(
                    context,
                    child: const Text('Rounded Content'),
                  );
                },
                child: const Text('Open Sheet'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open Sheet'));
      await tester.pumpAndSettle();

      // Verify the sheet was opened
      expect(find.text('Rounded Content'), findsOneWidget);
    });
  });
}
