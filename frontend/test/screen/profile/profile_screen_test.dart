import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordupx/screen/profile/profile_screen.dart';
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

  group('ProfileScreen Widget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.byType(ProfileScreen), findsOneWidget);
    });

    testWidgets('displays Profile in AppBar', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Profile'), findsOneWidget);
    });

    testWidgets('displays user avatar initial', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Hardcoded username is 'Mango', avatar shows 'M'
      expect(find.text('M'), findsOneWidget);
      expect(find.byType(CircleAvatar), findsOneWidget);
    });

    testWidgets('displays username and handle', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Mango'), findsOneWidget);
      expect(find.text('@Mango'), findsOneWidget);
    });

    testWidgets('displays change language option', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Change Language'), findsOneWidget);
      expect(find.byIcon(Icons.language), findsOneWidget);
    });

    testWidgets('displays change theme option', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Change Theme'), findsOneWidget);
      expect(find.byIcon(Icons.palette), findsOneWidget);
    });

    testWidgets('displays logout option in red', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Logout'), findsOneWidget);
      expect(find.byIcon(Icons.logout), findsOneWidget);
    });

    testWidgets('tapping logout shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancel button dismisses logout dialog', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Open dialog
      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      // Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to logout?'), findsNothing);
    });

    testWidgets('has forward arrow icons on settings items', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Three settings items (language, theme, logout) each have a trailing arrow
      expect(find.byIcon(Icons.arrow_forward_ios), findsNWidgets(3));
    });
  });
}
