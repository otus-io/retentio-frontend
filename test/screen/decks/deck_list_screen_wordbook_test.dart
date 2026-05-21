import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/screen/decks/deck_list_screen.dart';
import 'package:retentio/screen/decks/widgets/deck_create.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  group('DeckListScreen wordbook list & create flow', () {
    testWidgets('renders page title and subtitle', (tester) async {
      await tester.pumpWidget(buildTestableWidget(const DeckListScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Decks'), findsOneWidget);
      expect(find.text('Your study collections'), findsOneWidget);
    });

    testWidgets('create action opens bottom sheet with DeckCreate', (
      tester,
    ) async {
      await tester.pumpWidget(buildTestableWidget(const DeckListScreen()));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byIcon(LucideIcons.plus));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(DeckCreate), findsOneWidget);
      expect(find.text('Create Deck'), findsOneWidget);

      final scrollAncestor = find.ancestor(
        of: find.byType(DeckCreate),
        matching: find.byType(SingleChildScrollView),
      );
      expect(scrollAncestor, findsOneWidget);

      final scaffoldAncestor = find.ancestor(
        of: find.byType(DeckCreate),
        matching: find.byType(Scaffold),
      );
      expect(scaffoldAncestor, findsNothing);
    });
  });
}
