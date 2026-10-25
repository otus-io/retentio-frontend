import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/register/register_screen.dart';
import 'package:retentio/widgets/app_button.dart';

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

      expect(find.byType(AppButton), findsNWidgets(2));
      final context = tester.element(find.byType(RegisterScreen));
      final loc = AppLocalizations.of(context)!;
      expect(find.text(loc.register), findsWidgets);
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

    testWidgets('rejects a username outside 2 to 32 characters', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'a');
      await tester.enterText(find.byType(TextField).at(2), 'password1');
      await tester.enterText(find.byType(TextField).at(3), 'password1');
      await tester.tap(find.widgetWithText(AppButton, 'Register'));
      await tester.pump();

      expect(
        find.text('Username must be between 2 and 32 characters'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('rejects a username with an internal space', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'a b');
      await tester.enterText(find.byType(TextField).at(2), 'password1');
      await tester.enterText(find.byType(TextField).at(3), 'password1');
      await tester.tap(find.widgetWithText(AppButton, 'Register'));
      await tester.pump();

      expect(find.text('Username must not contain whitespace'), findsOneWidget);
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('rejects a short secret', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'ab');
      await tester.enterText(find.byType(TextField).at(2), 'short');
      await tester.enterText(find.byType(TextField).at(3), 'short');
      await tester.tap(find.widgetWithText(AppButton, 'Register'));
      await tester.pump();

      expect(
        find.text('Password must be at least 8 characters'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
    });

    testWidgets('rejects a long secret', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const RegisterScreen()),
      );
      await tester.pumpAndSettle();

      final longSecret = 'a' * 65;
      await tester.enterText(find.byType(TextField).at(0), 'a@b.com');
      await tester.enterText(find.byType(TextField).at(1), 'ab');
      await tester.enterText(find.byType(TextField).at(2), longSecret);
      await tester.enterText(find.byType(TextField).at(3), longSecret);
      await tester.tap(find.widgetWithText(AppButton, 'Register'));
      await tester.pump();

      expect(
        find.text('Password must be at most 64 characters'),
        findsOneWidget,
      );
      await tester.pump(const Duration(seconds: 2));
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
  });
}
