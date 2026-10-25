import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/reset_password/reset_password_screen.dart';
import 'package:retentio/widgets/app_button.dart';

import '../../helpers/test_wrapper.dart';

void main() {
  testWidgets('rejects a short new secret', (tester) async {
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        const ResetPasswordScreen(token: 'tok'),
      ),
    );
    await tester.pumpAndSettle();

    await tester.enterText(find.byType(TextField).at(0), 'short');
    await tester.enterText(find.byType(TextField).at(1), 'short');
    await tester.tap(find.widgetWithText(AppButton, 'Reset Password'));
    await tester.pump();

    expect(find.text('Password must be at least 8 characters'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });

  testWidgets('rejects a long new secret', (tester) async {
    await tester.pumpWidget(
      buildTestableWidgetWithoutProvider(
        const ResetPasswordScreen(token: 'tok'),
      ),
    );
    await tester.pumpAndSettle();

    final longSecret = 'a' * 65;
    await tester.enterText(find.byType(TextField).at(0), longSecret);
    await tester.enterText(find.byType(TextField).at(1), longSecret);
    await tester.tap(find.widgetWithText(AppButton, 'Reset Password'));
    await tester.pump();

    expect(find.text('Password must be at most 64 characters'), findsOneWidget);
    await tester.pump(const Duration(seconds: 2));
  });
}
