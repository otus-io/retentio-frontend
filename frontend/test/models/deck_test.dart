import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/models/deck.dart';

void main() {
  group('DeckOwner', () {
    test('fromJson parses username and email', () {
      final json = {'username': 'testuser', 'email': 'test@example.com'};
      final owner = DeckOwner.fromJson(json);
      expect(owner.username, 'testuser');
      expect(owner.email, 'test@example.com');
    });

    test('toJson serializes correctly', () {
      final owner = DeckOwner(username: 'user', email: 'user@test.com');
      final json = owner.toJson();
      expect(json['username'], 'user');
      expect(json['email'], 'user@test.com');
    });
  });

  group('DeckStats', () {
    test('fromJson parses all fields', () {
      final json = {
        'unseen_cards': 10,
        'facts_count': 50,
        'due_cards': 5,
        'cards_count': 20,
      };
      final stats = DeckStats.fromJson(json);
      expect(stats.unseenCards, 10);
      expect(stats.factsCount, 50);
      expect(stats.dueCards, 5);
      expect(stats.cardsCount, 20);
    });

    test('fromJson uses default 0 for missing fields', () {
      final stats = DeckStats.fromJson({});
      expect(stats.unseenCards, 0);
      expect(stats.factsCount, 0);
      expect(stats.dueCards, 0);
      expect(stats.cardsCount, 0);
    });

    test('toJson serializes correctly', () {
      final stats = DeckStats(
        unseenCards: 5,
        factsCount: 25,
        dueCards: 3,
        cardsCount: 30,
      );
      final json = stats.toJson();
      expect(json['unseen_cards'], 5);
      expect(json['facts_count'], 25);
      expect(json['due_cards'], 3);
      expect(json['cards_count'], 30);
    });
  });

  group('Deck', () {
    group('fromJson', () {
      test('parses deck with owner as object', () {
        final json = {
          'id': 'deck-1',
          'name': 'Test Deck',
          'templates': [
            [0, 1],
          ],
          'stats': {
            'unseen_cards': 5,
            'facts_count': 10,
            'due_cards': 2,
            'cards_count': 20,
          },
          'rate': 10,
          'owner': {'username': 'owner1', 'email': 'owner@test.com'},
          'fields': ['front', 'back'],
        };
        final deck = Deck.fromJson(json);
        expect(deck.id, 'deck-1');
        expect(deck.name, 'Test Deck');
        expect(deck.templates, [
          [0, 1],
        ]);
        expect(deck.rate, 10);
        expect(deck.owner.username, 'owner1');
        expect(deck.owner.email, 'owner@test.com');
        expect(deck.fields, ['front', 'back']);
      });

      test('parses deck with owner as string', () {
        final json = {
          'id': 'deck-2',
          'name': 'Deck 2',
          'templates': [],
          'stats': <String, dynamic>{},
          'owner': 'string_owner',
          'fields': [],
        };
        final deck = Deck.fromJson(json);
        expect(deck.owner.username, 'string_owner');
        expect(deck.owner.email, '');
      });

      test('parses templates as nested list  [[0,1]]', () {
        final json = {
          'id': 'd',
          'name': 'n',
          'templates': [
            [0, 1],
          ],
          'stats': <String, dynamic>{},
          'owner': 'o',
          'fields': [],
        };
        final deck = Deck.fromJson(json);
        expect(deck.templates, [
          [0, 1],
        ]);
      });

      test('parses templates as flat list [[0.1],[1,0]]', () {
        final json = {
          'id': 'd',
          'name': 'n',
          'templates': [
            [0, 1],
            [1, 0],
          ],
          'stats': <String, dynamic>{},
          'owner': 'o',
          'fields': [],
        };
        final deck = Deck.fromJson(json);
        expect(deck.templates, [
          [0, 1],
          [1, 0],
        ]);
      });

      test('uses field when fields is missing', () {
        final json = {
          'id': 'd',
          'name': 'n',
          'templates': [],
          'stats': <String, dynamic>{},
          'owner': 'o',
          'field': ['a', 'b'],
        };
        final deck = Deck.fromJson(json);
        expect(deck.fields, ['a', 'b']);
      });

      test('parses createdAt and updatedAt', () {
        final json = {
          'id': 'd',
          'name': 'n',
          'templates': [],
          'stats': <String, dynamic>{},
          'owner': 'o',
          'fields': [],
          'created_at': '2024-01-15T10:30:00.000Z',
          'updated_at': '2024-01-16T12:00:00.000Z',
        };
        final deck = Deck.fromJson(json);
        expect(deck.createdAt, isNotNull);
        expect(deck.updatedAt, isNotNull);
        expect(deck.createdAt!.toIso8601String(), contains('2024-01-15'));
        expect(deck.updatedAt!.toIso8601String(), contains('2024-01-16'));
      });
    });

    group('toJson', () {
      test('serializes deck correctly', () {
        final deck = Deck(
          id: 'deck-1',
          name: 'My Deck',
          templates: <List<int>>[
            <int>[0],
          ],
          stats: DeckStats(
            unseenCards: 5,
            factsCount: 10,
            dueCards: 2,
            cardsCount: 20,
          ),
          rate: 1,
          owner: DeckOwner(username: 'u', email: 'e@e.com'),
          fields: <String>['f1'],
          minInterval: 1,
          defInterval: 1,
          maxInterval: 365,
        );
        final json = deck.toJson();
        expect(json['id'], 'deck-1');
        expect(json['name'], 'My Deck');
        expect(json['templates'], [
          [0],
        ]);
        expect(json['rate'], 1);
      });
    });

    group('progress', () {
      test('returns 0 when cardsCount is 0', () {
        final deck = Deck(
          id: 'd',
          name: 'n',
          templates: <List<int>>[],
          stats: DeckStats(
            unseenCards: 0,
            factsCount: 0,
            dueCards: 0,
            cardsCount: 0,
          ),
          rate: 0,
          owner: DeckOwner(username: '', email: ''),
          fields: <String>[],
          minInterval: 0,
          defInterval: 0,
          maxInterval: 0,
        );
        expect(deck.progress, 0.0);
      });

      test('calculates progress percentage correctly', () {
        final deck = Deck(
          id: 'd',
          name: 'n',
          templates: <List<int>>[],
          stats: DeckStats(
            unseenCards: 5,
            factsCount: 10,
            dueCards: 2,
            cardsCount: 20,
          ),
          rate: 0,
          owner: DeckOwner(username: '', email: ''),
          fields: <String>[],
          minInterval: 0,
          defInterval: 0,
          maxInterval: 0,
        );
        expect(deck.progress, 75.0); // 15/20 * 100
      });

      test('clamps progress to 100', () {
        final deck = Deck(
          id: 'd',
          name: 'n',
          templates: <List<int>>[],
          stats: DeckStats(
            unseenCards: 0,
            factsCount: 0,
            dueCards: 0,
            cardsCount: 10,
          ),
          rate: 0,
          owner: DeckOwner(username: '', email: ''),
          fields: <String>[],
          minInterval: 0,
          defInterval: 0,
          maxInterval: 0,
        );
        expect(deck.progress, 100.0);
      });
    });

    group('totalCards, learnedCards, reviewCards', () {
      test('returns correct values from stats', () {
        final deck = Deck(
          id: 'd',
          name: 'n',
          templates: <List<int>>[],
          stats: DeckStats(
            unseenCards: 8,
            factsCount: 20,
            dueCards: 5,
            cardsCount: 25,
          ),
          rate: 0,
          owner: DeckOwner(username: '', email: ''),
          fields: <String>[],
          minInterval: 0,
          defInterval: 0,
          maxInterval: 0,
        );
        expect(deck.totalCards, 25);
        expect(deck.learnedCards, 17);
        expect(deck.reviewCards, 5);
      });
    });
  });
}
