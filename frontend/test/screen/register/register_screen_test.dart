import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/screen/register/register_screen.dart';

import '../../helpers/test_wrapper.dart';

void main() {
  group('RegisterScreen Widget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('displays register title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      // "Register" appears as both title and button text
      expect(find.text('Register'), findsWidgets);
    });

    testWidgets('displays all four form fields', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(4));
      expect(find.text('Email'), findsOneWidget);
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
      expect(find.text('Confirm Password'), findsOneWidget);
    });

    testWidgets('displays register button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displays back to login button', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Back to Login'), findsOneWidget);
    });

    testWidgets('email field has email keyboard type', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      // The first TextField is the email field
      final emailField = tester.widget<TextField>(find.byType(TextField).first);
      expect(emailField.keyboardType, TextInputType.emailAddress);
    });

    testWidgets('password fields are obscured', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      final textFields = tester
          .widgetList<TextField>(find.byType(TextField))
          .toList();
      // Third field (index 2) is password, fourth (index 3) is confirm password
      expect(textFields[2].obscureText, isTrue);
      expect(textFields[3].obscureText, isTrue);
    });

    testWidgets('can enter text in email field', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'test@example.com');
      await tester.pump();

      expect(find.text('test@example.com'), findsOneWidget);
    });

    testWidgets('can enter text in username field', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(1), 'testuser');
      await tester.pump();

      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('password and confirm password are independent fields', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(2), 'pass1');
      await tester.enterText(find.byType(TextField).at(3), 'pass2');
      await tester.pump();

      expect(find.text('pass1'), findsOneWidget);
      expect(find.text('pass2'), findsOneWidget);
    });

    testWidgets('accepts very long email', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      final longEmail = '${'a' * 200}@${'b' * 50}.com';
      await tester.enterText(find.byType(TextField).first, longEmail);
      await tester.pump();

      expect(find.text(longEmail), findsOneWidget);
    });

    testWidgets('tap register with all fields empty does not crash', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.widgetWithText(ElevatedButton, 'Register'));
      await tester.pump();

      expect(find.byType(RegisterScreen), findsOneWidget);
    });

    testWidgets('accepts special characters in email', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      const email = r'user+tag<>@example.co.uk';
      await tester.enterText(find.byType(TextField).first, email);
      await tester.pump();

      expect(find.text(email), findsOneWidget);
    });
  });
}
