import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/login/widgets/forgot_password.dart';
import 'package:retentio/widgets/app_button.dart';
import 'package:retentio/widgets/app_toast.dart';

import '../../../helpers/test_wrapper.dart';

void main() {
  tearDown(AppToast.dismiss);

  group('ForgotPassword Widget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          const Scaffold(body: ForgotPassword()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ForgotPassword), findsOneWidget);
    });

    testWidgets('displays forgot password title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          const Scaffold(body: ForgotPassword()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('displays email text field', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          const Scaffold(body: ForgotPassword()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsOneWidget);
      expect(find.text('Email'), findsOneWidget);
    });

    testWidgets('displays reset password button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          const Scaffold(body: ForgotPassword()),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.byType(AppButton), findsOneWidget);
    });

    testWidgets('shows toast when submitting with empty email', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          const Scaffold(body: ForgotPassword()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.byType(AppButton));
      await tester.pump();

      expect(find.text('Please fill all fields'), findsOneWidget);

      // AppToast schedules a 2s dismiss timer.
      await tester.pump(const Duration(seconds: 2));
      await tester.pump();
    });

    testWidgets('can enter email text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          const Scaffold(body: ForgotPassword()),
        ),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField), 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('email field has email keyboard type', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          const Scaffold(body: ForgotPassword()),
        ),
      );
      await tester.pumpAndSettle();

      final textField = tester.widget<TextField>(find.byType(TextField));
      expect(textField.keyboardType, TextInputType.emailAddress);
    });
  });
}
