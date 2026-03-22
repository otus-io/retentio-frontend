import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/learn/learn_screen.dart';
import 'package:retentio/screen/learn/providers/deck_provider.dart';
import 'package:retentio/screen/learn/widgets/create_deck_widget.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:retentio/services/storage/hydrated_storage.dart';

import '../../helpers/fake_deck_list_notifier.dart';
import '../../helpers/in_memory_hydrated_storage.dart';
import '../../helpers/test_wrapper.dart';

void main() {
  final sampleDeck = Deck.fromJson({
    'id': 'deck-wb-1',
    'name': 'Morning vocab',
    'stats': {
      'cards_count': 12,
      'unseen_cards': 3,
      'due_cards': 2,
      'facts_count': 5,
    },
    'rate': 20,
    'owner': {'username': 'u', 'email': 'u@t.com'},
    'fields': ['English', 'Chinese'],
  });

  setUpAll(() async {
    SharedPreferences.setMockInitialValues({});
    HydratedStorage.instance = InMemoryHydratedStorage();
  });

  tearDownAll(() {
    HydratedStorage.instance = null;
  });

  group('LearnScreen wordbook list & create flow', () {
    testWidgets('lists deck names from provider', (tester) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const LearnScreen(),
          overrides: [
            deckListProvider.overrideWith(
              () => FakeDeckListNotifier([sampleDeck]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Morning vocab'), findsOneWidget);
    });

    testWidgets('create action opens bottom sheet with CreateDeckWidget', (
      tester,
    ) async {
      await tester.pumpWidget(
        buildTestableWidgetWithOverrides(
          const LearnScreen(),
          overrides: [
            deckListProvider.overrideWith(
              () => FakeDeckListNotifier([sampleDeck]),
            ),
          ],
        ),
      );
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      await tester.tap(find.byIcon(LucideIcons.squarePlus));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.byType(CreateDeckWidget), findsOneWidget);
      expect(find.text('Create Deck'), findsOneWidget);

      final sheet = tester.widget<DraggableScrollableSheet>(
        find.byType(DraggableScrollableSheet),
      );
      expect(sheet.initialChildSize, 0.5);
      expect(sheet.minChildSize, 0.4);
    });
  });
}
