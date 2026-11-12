import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/qa_verified_badge.dart';

import '../helpers/test_wrapper.dart';

void main() {
  testWidgets('paints a labelled check badge at the requested size', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        const Scaffold(body: QaVerifiedBadge(size: 20)),
      ),
    );

    expect(tester.getSize(find.byType(QaVerifiedBadge)), const Size(20, 20));
    final paint = tester.widget<CustomPaint>(
      find.descendant(
        of: find.byType(QaVerifiedBadge),
        matching: find.byType(CustomPaint),
      ),
    );
    expect(paint.painter, isA<QaVerifiedBadgePainter>());
    expect(find.byTooltip('Fully QA-verified'), findsOneWidget);
    expect(find.bySemanticsLabel('Fully QA-verified'), findsOneWidget);
  });

  test('repaints only when a color changes', () {
    const a = QaVerifiedBadgePainter(ring: Colors.grey, check: Colors.green);
    const same = QaVerifiedBadgePainter(ring: Colors.grey, check: Colors.green);
    const other = QaVerifiedBadgePainter(ring: Colors.grey, check: Colors.blue);
    expect(a.shouldRepaint(same), isFalse);
    expect(a.shouldRepaint(other), isTrue);
  });
}
