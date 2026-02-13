import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:wordupx/screen/profile/profile_screen.dart';

import '../../helpers/test_wrapper.dart';

void main() {
  setUpAll(setupTestEnvironment);
  tearDownAll(tearDownTestEnvironment);

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

    testWidgets('displays change language option', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      expect(find.text('Change Language'), findsOneWidget);
      expect(find.byIcon(LucideIcons.globe), findsOneWidget);
    });

    testWidgets('tapping logout shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Logout'));
      await tester.pumpAndSettle();

      expect(find.text('Are you sure you want to logout?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('has forward arrow icons on settings items', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      // Three settings items (language, theme, logout) each have a trailing arrow
      expect(find.byIcon(Icons.arrow_forward_ios), findsNWidgets(3));
    });
  });
}
