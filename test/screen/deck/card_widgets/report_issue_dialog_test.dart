import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/card_widgets/report_issue_dialog.dart';
import 'package:retentio/widgets/contribute_help_button.dart';

import '../../../helpers/test_wrapper.dart';

void main() {
  testWidgets('Fix it yourself closes the report and hands off', (
    tester,
  ) async {
    var fixed = 0;
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        Scaffold(
          body: Builder(
            builder: (context) => TextButton(
              onPressed: () => showReportIssueDialog(
                context: context,
                importDeckId: 'imp-1',
                factId: 'fact-1',
                onFixYourself: () => fixed++,
              ),
              child: const Text('open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
    expect(find.byType(ContributeHelpButton), findsOneWidget);
    expect(find.textContaining('Know the right answer?'), findsOneWidget);

    await tester.tap(find.text('Fix it yourself'));
    await tester.pumpAndSettle();

    expect(fixed, 1);
    expect(find.text('Fix it yourself'), findsNothing);
  });
}
