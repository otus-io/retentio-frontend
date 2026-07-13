import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/profile/profile_screen.dart';

import '../../helpers/fake_profile_api_interceptor.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  late FakeProfileApiInterceptor interceptor;

  setUpAll(() async {
    await setupTestEnvironment();
    interceptor = attachFakeProfileApiInterceptor();
  });

  tearDownAll(() {
    detachFakeProfileApiInterceptor(interceptor);
    tearDownTestEnvironment();
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

    testWidgets('displays change language option', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ProfileScreen));
      final loc = AppLocalizations.of(context)!;
      expect(find.text(loc.changeLanguage), findsOneWidget);
      expect(find.byIcon(LucideIcons.globe), findsOneWidget);
    });

    testWidgets('tapping logout shows confirmation dialog', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(ProfileScreen));
      final loc = AppLocalizations.of(context)!;

      await tester.tap(find.text(loc.logout));
      await tester.pumpAndSettle();

      expect(find.text(loc.logoutConfirmMessage), findsOneWidget);
      expect(find.text(loc.cancel), findsOneWidget);
    });

    testWidgets('has forward arrow icons on settings items', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const ProfileScreen()));
      await tester.pumpAndSettle();

      final tiles = tester.widgetList<ListTile>(find.byType(ListTile)).toList();
      expect(tiles, hasLength(3));
      for (final tile in tiles) {
        expect(tile.trailing, isA<Icon>());
      }
    });
  });
}
