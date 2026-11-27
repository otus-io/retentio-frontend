import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/widgets/contribute_help_button.dart';

import '../helpers/test_wrapper.dart';

void main() {
  testWidgets('tapping ? explains contributions and Got it closes', (
    tester,
  ) async {
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        const Scaffold(body: ContributeHelpButton()),
      ),
    );

    await tester.tap(find.byIcon(LucideIcons.circleHelp));
    await tester.pumpAndSettle();
    expect(find.text('Improve this deck together'), findsOneWidget);
    expect(find.textContaining('sent to the author to review'), findsOneWidget);

    await tester.tap(find.text('Got it'));
    await tester.pumpAndSettle();
    expect(find.text('Improve this deck together'), findsNothing);
  });
}
