import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
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

    testWidgets('displays welcome text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.text('Welcome to Retentio'), findsOneWidget);
    });

    testWidgets('displays instruction text', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(
        find.text('Start learning by checking your decks in the Deck tab'),
        findsOneWidget,
      );
    });

    testWidgets('displays waving hand icon', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(const HomeScreen()),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.waving_hand), findsOneWidget);
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

      // The hardcoded English text should still appear
      expect(find.text('Welcome to Retentio'), findsOneWidget);
    });
  });
}
