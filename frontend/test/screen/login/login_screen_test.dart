import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordupx/screen/login/login_screen.dart';
import 'package:wordupx/services/storage/hydrated_storage.dart';

import '../../helpers/in_memory_hydrated_storage.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    HydratedStorage.instance = InMemoryHydratedStorage();
  });

  tearDownAll(() {
    HydratedStorage.instance = null;
  });

  group('LoginScreen Widget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('displays app name', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Wordupx'), findsOneWidget);
    });

    testWidgets('displays username and password fields', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(TextField), findsNWidgets(2));
      expect(find.text('Username'), findsOneWidget);
      expect(find.text('Password'), findsOneWidget);
    });

    testWidgets('displays login button', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Login'), findsOneWidget);
      expect(find.byType(ElevatedButton), findsOneWidget);
    });

    testWidgets('displays register link', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Register'), findsOneWidget);
    });

    testWidgets('displays forgot password link', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('password field is obscured', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      // The second TextField is the password field
      final passwordField = tester.widget<TextField>(
        find.byType(TextField).last,
      );
      expect(passwordField.obscureText, isTrue);
    });

    testWidgets('can enter username', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, 'testuser');
      await tester.pump();

      expect(find.text('testuser'), findsOneWidget);
    });

    testWidgets('can enter password', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).last, 'secret123');
      await tester.pump();

      expect(find.text('secret123'), findsOneWidget);
    });

    testWidgets('has theme toggle icon button', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('has language dropdown', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownButton<Locale>), findsOneWidget);
    });

    testWidgets('tap login with empty fields does not crash', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Login'));
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('accepts very long username', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final longName = 'a' * 500;
      await tester.enterText(find.byType(TextField).first, longName);
      await tester.pump();

      expect(find.text(longName), findsOneWidget);
    });

    testWidgets('accepts very long password', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      final longPass = 'x' * 300;
      await tester.enterText(find.byType(TextField).last, longPass);
      await tester.pump();

      expect(find.text(longPass), findsOneWidget);
    });

    testWidgets('accepts whitespace-only input', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      await tester.enterText(find.byType(TextField).first, '   \t  ');
      await tester.enterText(find.byType(TextField).last, ' ');
      await tester.pump();

      expect(find.byType(LoginScreen), findsOneWidget);
    });

    testWidgets('accepts special characters in username', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LoginScreen()));
      await tester.pumpAndSettle();

      const special = 'user<>"&@test';
      await tester.enterText(find.byType(TextField).first, special);
      await tester.pump();

      expect(find.text(special), findsOneWidget);
    });
  });
}
