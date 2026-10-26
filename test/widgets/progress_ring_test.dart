import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/progress_ring.dart';

Future<void> _pump(WidgetTester tester, double? value) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: ProgressRing(value: value)),
  ),
);

void main() {
  testWidgets('shows the whole percent inside the ring', (tester) async {
    await _pump(tester, 0.429);

    expect(find.text('42%'), findsOneWidget);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      0.429,
    );
  });

  testWidgets('clamps values outside 0 to 1', (tester) async {
    await _pump(tester, 1.5);
    expect(find.text('100%'), findsOneWidget);

    await _pump(tester, -1);
    expect(find.text('0%'), findsOneWidget);
  });

  testWidgets('is an indeterminate spinner without a number when null', (
    tester,
  ) async {
    await _pump(tester, null);

    expect(find.textContaining('%'), findsNothing);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      isNull,
    );
  });

  testWidgets('hides the number when showPercent is off', (tester) async {
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: ProgressRing(value: 0.5, size: 16, showPercent: false),
        ),
      ),
    );

    expect(find.textContaining('%'), findsNothing);
    expect(
      tester
          .widget<CircularProgressIndicator>(
            find.byType(CircularProgressIndicator),
          )
          .value,
      0.5,
    );
  });

  testWidgets('exposes the percent to accessibility once', (tester) async {
    final handle = tester.ensureSemantics();
    await _pump(tester, 0.5);

    expect(find.bySemanticsLabel('50%'), findsOneWidget);
    handle.dispose();
  });
}
