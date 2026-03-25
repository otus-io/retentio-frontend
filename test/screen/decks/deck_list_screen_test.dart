import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retentio/screen/decks/deck_list_screen.dart';
import 'package:retentio/services/storage/hydrated_storage.dart';

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

  group('DeckListScreen', () {
    testWidgets('renders without errors', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const DeckListScreen()));
      // Only pump once — provider triggers async DeckService call
      await tester.pump();

      expect(find.byType(DeckListScreen), findsOneWidget);
    });

    testWidgets('displays Decks in AppBar', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const DeckListScreen()));
      await tester.pump();

      expect(find.text('Decks'), findsOneWidget);
    });

    testWidgets('shows loading or error state', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const DeckListScreen()));
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
      await tester.pumpWidget(buildTestableWidget(const DeckListScreen()));
      await tester.pump();

      expect(find.byType(AppBar), findsOneWidget);
      expect(find.byType(IconButton), findsOneWidget);
    });

    testWidgets('has Scaffold structure', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const DeckListScreen()));
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
    });
  });
}
