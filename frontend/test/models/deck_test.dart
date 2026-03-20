import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck.dart';

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
  });

  group('Deck', () {
    group('fromJson', () {
      test('parses deck with owner as object', () {
        final json = {
          'id': 'deck-1',
          'name': 'Test Deck',
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
  });
}
