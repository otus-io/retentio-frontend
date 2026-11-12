import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/widgets/qa_verified_badge.dart';

import '../helpers/test_wrapper.dart';

void main() {
  testWidgets('shows a labelled V badge at the requested size', (tester) async {
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        const Scaffold(body: QaVerifiedBadge(size: 20)),
      ),
    );

    expect(find.text('V'), findsOneWidget);
    expect(tester.getSize(find.byType(QaVerifiedBadge)), const Size(20, 20));
    expect(find.byTooltip('Fully QA-verified'), findsOneWidget);
    expect(find.bySemanticsLabel('Fully QA-verified'), findsOneWidget);
  });
}
