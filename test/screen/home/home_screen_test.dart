import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/l10n/app_localizations.dart';
import 'package:retentio/screen/home/home_screen.dart';

import '../../helpers/test_wrapper.dart';

void main() {
  group('HomeScreen Widget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(HomeScreen), findsOneWidget);
    });

    testWidgets('displays learning path text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Learning Path'), findsOneWidget);
    });

    testWidgets('displays focus instruction text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text(
          'Finish one review round first, then add new facts from your study notes.',
        ),
        findsOneWidget,
      );
    });

    testWidgets('displays daily goal icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(LucideIcons.flame), findsOneWidget);
    });

    testWidgets('has AppBar with Home title', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Home'), findsOneWidget);
    });

    testWidgets('uses Scaffold as root widget', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });

    testWidgets('renders correctly with Chinese locale', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          const HomeScreen(),
          locale: const Locale('zh'),
        ),
      );
      await tester.pumpAndSettle();

      final context = tester.element(find.byType(HomeScreen));
      final loc = AppLocalizations.of(context)!;
      expect(find.text(loc.homeLearningPath), findsOneWidget);
    });
  });
}
