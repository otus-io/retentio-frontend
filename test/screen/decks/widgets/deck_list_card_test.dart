import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck.dart';
import 'package:retentio/screen/decks/widgets/deck_list_card.dart';

import '../../../helpers/test_wrapper.dart';

void main() {
  group('DeckListCard', () {
    testWidgets('shows two decimals when cumulative progress is below 1%', (
      tester,
    ) async {
      final deck = Deck.fromJson({
        'id': 'deck-test-1',
        'name': 'Tiny Progress',
        'stats': {
          'cards_count': 2387,
          'unseen_cards': 2381,
          'due_cards': 0,
          'facts_count': 10,
          'reviewed_cards': 6,
          'hidden_cards': 0,
          'new_cards_today': 0,
          'last_reviewed_at': 0,
        },
        'rate': 10,
        'min_interval': 60,
        'def_interval': 300,
        'max_interval': 86400,
        'owner': {'username': 'u', 'email': 'u@t.com'},
        'fields': ['Front', 'Back'],
      });

      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          Scaffold(body: DeckListCard(deck: deck)),
        ),
      );

      expect(find.text('6/2387 (0.25%)'), findsOneWidget);
    });

    testWidgets('hides publish action for imported decks', (tester) async {
      final deck = Deck.fromJson({
        'id': 'deck-imported-1',
        'name': 'Imported Deck',
        'source_deck_id': 'source-123',
        'stats': {
          'cards_count': 10,
          'unseen_cards': 5,
          'due_cards': 2,
          'facts_count': 4,
          'reviewed_cards': 5,
          'hidden_cards': 0,
          'new_cards_today': 0,
          'last_reviewed_at': 0,
        },
        'rate': 30,
        'min_interval': 60,
        'def_interval': 300,
        'max_interval': 86400,
        'owner': {'username': 'u', 'email': 'u@t.com'},
        'fields': ['Front', 'Back'],
      });

      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(
          Scaffold(body: DeckListCard(deck: deck)),
        ),
      );

      expect(find.byTooltip('Publish Deck'), findsNothing);
    });
  });
}
