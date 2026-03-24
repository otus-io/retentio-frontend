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

    test(
      'fromJson parses reviewed, hidden, new_cards_today, last_reviewed_at',
      () {
        final stats = DeckStats.fromJson({
          'cards_count': 1,
          'facts_count': 2,
          'unseen_cards': 3,
          'reviewed_cards': 4,
          'due_cards': 5,
          'hidden_cards': 6,
          'new_cards_today': 7,
          'last_reviewed_at': 1700000000,
        });
        expect(stats.reviewedCards, 4);
        expect(stats.hiddenCards, 6);
        expect(stats.newCardsToday, 7);
        expect(stats.lastReviewedAt, 1700000000);
      },
    );

    test('toJson round-trips with fromJson', () {
      final original = DeckStats(
        cardsCount: 1,
        factsCount: 2,
        unseenCards: 3,
        reviewedCards: 4,
        dueCards: 5,
        hiddenCards: 6,
        newCardsToday: 7,
        lastReviewedAt: 8,
      );
      final again = DeckStats.fromJson(original.toJson());
      expect(again.cardsCount, original.cardsCount);
      expect(again.lastReviewedAt, original.lastReviewedAt);
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

      test('parses min_interval, def_interval, max_interval', () {
        final json = {
          'id': 'd',
          'name': 'n',
          'stats': <String, dynamic>{},
          'owner': 'o',
          'fields': [],
          'min_interval': 60,
          'def_interval': 300,
          'max_interval': 86400,
        };
        final deck = Deck.fromJson(json);
        expect(deck.minInterval, 60);
        expect(deck.defInterval, 300);
        expect(deck.maxInterval, 86400);
      });

      test('toJson includes intervals and nested stats', () {
        final deck = Deck(
          id: 'id1',
          name: 'N',
          stats: DeckStats(
            cardsCount: 10,
            factsCount: 1,
            unseenCards: 2,
            reviewedCards: 3,
            dueCards: 4,
            hiddenCards: 0,
            newCardsToday: 0,
            lastReviewedAt: 0,
          ),
          rate: 5,
          owner: DeckOwner(username: 'u', email: 'e'),
          fields: const ['a'],
          minInterval: 1,
          defInterval: 2,
          maxInterval: 3,
        );
        final json = deck.toJson();
        expect(json['min_interval'], 1);
        expect(json['def_interval'], 2);
        expect(json['max_interval'], 3);
        expect(json['stats'], isA<Map<String, dynamic>>());
      });

      test('progress is 0 when cardsCount is 0', () {
        final deck = Deck(
          id: 'd',
          name: 'n',
          stats: DeckStats(
            cardsCount: 0,
            factsCount: 0,
            unseenCards: 0,
            reviewedCards: 0,
            dueCards: 0,
            hiddenCards: 0,
            newCardsToday: 0,
            lastReviewedAt: 0,
          ),
          rate: 0,
          owner: DeckOwner(username: 'u', email: ''),
          fields: const [],
          minInterval: 0,
          defInterval: 0,
          maxInterval: 0,
        );
        expect(deck.progress, 0.0);
      });

      test('progress reflects learned fraction', () {
        final deck = Deck(
          id: 'd',
          name: 'n',
          stats: DeckStats(
            cardsCount: 100,
            factsCount: 0,
            unseenCards: 40,
            reviewedCards: 0,
            dueCards: 0,
            hiddenCards: 0,
            newCardsToday: 0,
            lastReviewedAt: 0,
          ),
          rate: 0,
          owner: DeckOwner(username: 'u', email: ''),
          fields: const [],
          minInterval: 0,
          defInterval: 0,
          maxInterval: 0,
        );
        expect(deck.progress, 60.0);
        expect(deck.learnedCards, 60);
        expect(deck.totalCards, 100);
        expect(deck.reviewCards, 0);
      });
    });
  });
}
