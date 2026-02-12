import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:wordupx/screen/learn/learn_screen.dart';
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

  group('LearnScreen Widget', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LearnScreen()));
      // Only pump once — provider triggers async DeckService call
      await tester.pump();

      expect(find.byType(LearnScreen), findsOneWidget);
    });

    testWidgets('displays Learn in AppBar', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LearnScreen()));
      await tester.pump();

      expect(find.text('Learn'), findsOneWidget);
    });

    testWidgets('shows loading or error state', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LearnScreen()));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // The provider triggers an async DeckService call that may
      // resolve quickly in test environment. Check for either state.
      final hasLoading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;
      final hasError = find.byIcon(Icons.error_outline).evaluate().isNotEmpty;
      final hasEmpty = find.byIcon(Icons.inbox_outlined).evaluate().isNotEmpty;

      expect(hasLoading || hasError || hasEmpty, isTrue);
    });

    testWidgets('has AppBar with add button', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LearnScreen()));
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('has Scaffold structure', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const LearnScreen()));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
