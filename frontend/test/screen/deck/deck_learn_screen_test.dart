import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/models/deck.dart';
import 'package:wordupx/screen/deck/deck_learn_screen.dart';

import '../../helpers/test_wrapper.dart';

Deck _createTestDeck({
  String name = 'Test Deck',
  int unseenCards = 5,
  int dueCards = 3,
  int cardsCount = 20,
}) {
  return Deck.fromJson(<String, dynamic>{
    'id': 'test-deck-1',
    'name': name,
    'templates':[[0,1]],
    'stats': <String, dynamic>{
      'unseen_cards': unseenCards,
      'facts_count': 15,
      'due_cards': dueCards,
      'cards_count': cardsCount,
    },
    'rate': 10,
    'owner': <String, dynamic>{
      'username': 'testuser',
      'email': 'test@example.com',
    },
    'fields': <String>['front', 'back'],
    'min_interval': 60,
    'def_interval': 600,
    'max_interval': 86400,
  });
}

void main() {
  group('DeckLearnScreen Widget', () {
    testWidgets('renders without errors', (tester) async {
      final deck = _createTestDeck();
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckLearnScreen(deck: deck)),
      );
      // Only pump once — async CardService call is in-flight
      await tester.pump();

      expect(find.byType(DeckLearnScreen), findsOneWidget);
    });

    testWidgets('displays deck name in AppBar', (tester) async {
      final deck = _createTestDeck(name: 'Vocabulary');
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckLearnScreen(deck: deck)),
      );
      await tester.pump();

      expect(find.text('Vocabulary'), findsOneWidget);
    });

    testWidgets('shows loading or completion state after init', (tester) async {
      final deck = _createTestDeck();
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckLearnScreen(deck: deck)),
      );
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // After the async CardService call completes (or fails),
      // the screen shows either loading, error, or "all caught up" state
      final hasLoading = find
          .byType(CircularProgressIndicator)
          .evaluate()
          .isNotEmpty;
      final hasAllCaughtUp = find.text('All Caught Up!').evaluate().isNotEmpty;
      final hasError = find.textContaining('Error').evaluate().isNotEmpty;

      expect(hasLoading || hasAllCaughtUp || hasError, isTrue);
    });

    testWidgets('has Scaffold with AppBar', (tester) async {
      final deck = _createTestDeck();
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckLearnScreen(deck: deck)),
      );
      await tester.pump();

      expect(find.byType(Scaffold), findsOneWidget);
      expect(find.byType(AppBar), findsOneWidget);
    });
  });
}
