import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/screen/login/widgets/forgot_password.dart';

import '../../../helpers/test_wrapper.dart';

void main() {
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
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('shows snackbar when submitting with empty email', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          const Scaffold(body: ForgotPassword()),
        ),
      );
      await tester.pumpAndSettle();

      // Tap reset password without entering email
      await tester.tap(find.byType(ElevatedButton));
      await tester.pump();

      expect(find.text('Please fill all fields'), findsOneWidget);
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
