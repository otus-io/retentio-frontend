import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/models/deck.dart';
import 'package:wordupx/screen/deck/deck_detail_screen.dart';

import '../../helpers/test_wrapper.dart';

Deck _createTestDeck({
  String id = 'test-deck-1',
  String name = 'Test Deck',
  int cardsCount = 20,
  int unseenCards = 5,
  int dueCards = 3,
  int factsCount = 15,
  List<List<int>> templates = const [
    [0, 1]
  ],
}) {
  return Deck.fromJson(<String, dynamic>{
    'id': id,
    'name': name,
    'templates':templates,
    'stats': <String, dynamic>{
      'unseen_cards': unseenCards,
      'facts_count': factsCount,
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
  group('DeckDetailScreen Widget', () {
    testWidgets('renders without errors', (tester) async {
      final deck = _createTestDeck();
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      expect(find.byType(DeckDetailScreen), findsOneWidget);
    });

    testWidgets('displays deck name in AppBar', (tester) async {
      final deck = _createTestDeck(name: 'My Vocabulary');
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      expect(find.text('My Vocabulary'), findsOneWidget);
    });

    testWidgets('displays total cards stat', (tester) async {
      final deck = _createTestDeck(cardsCount: 25);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      expect(find.text('25'), findsOneWidget);
      expect(find.text('Total'), findsOneWidget);
    });

    testWidgets('displays new cards stat', (tester) async {
      final deck = _createTestDeck(unseenCards: 8, cardsCount: 25);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      expect(find.text('8'), findsOneWidget);
      expect(find.text('New'), findsOneWidget);
    });

    testWidgets('displays due cards stat', (tester) async {
      final deck = _createTestDeck(dueCards: 7);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      expect(find.text('7'), findsOneWidget);
      expect(find.text('Due'), findsOneWidget);
    });

    testWidgets('displays learned cards stat', (tester) async {
      final deck = _createTestDeck(cardsCount: 20, unseenCards: 5);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      // learnedCards = cardsCount - unseenCards = 15
      expect(find.text('15'), findsOneWidget);
      expect(find.text('Learned'), findsOneWidget);
    });

    testWidgets('shows start learning button when cards available', (
      tester,
    ) async {
      final deck = _createTestDeck(unseenCards: 5, dueCards: 3);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      expect(find.text('Start Learning'), findsOneWidget);
      expect(find.byIcon(Icons.play_arrow), findsOneWidget);
    });

    testWidgets('shows all caught up when no cards to study', (tester) async {
      final deck = _createTestDeck(unseenCards: 0, dueCards: 0);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      expect(find.text('All Caught Up!'), findsOneWidget);
    });

    testWidgets('start learning button is disabled when no cards', (
      tester,
    ) async {
      final deck = _createTestDeck(unseenCards: 0, dueCards: 0);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNull);
    });

    testWidgets('start learning button is enabled when cards available', (
      tester,
    ) async {
      final deck = _createTestDeck(unseenCards: 3, dueCards: 2);
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      final button = tester.widget<ElevatedButton>(find.byType(ElevatedButton));
      expect(button.onPressed, isNotNull);
    });

    testWidgets('displays stat icons', (tester) async {
      final deck = _createTestDeck();
      await tester.pumpWidget(
        buildTestableWidgetWithoutProvider(DeckDetailScreen(deck: deck)),
      );
      await tester.pumpAndSettle();

      expect(find.byIcon(Icons.style), findsOneWidget);
      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.byIcon(Icons.refresh), findsOneWidget);
      expect(find.byIcon(Icons.check_circle), findsOneWidget);
    });
  });
}
