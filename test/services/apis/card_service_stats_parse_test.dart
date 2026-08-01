import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/services/apis/card_service.dart';

void main() {
  group('parseDeckCardsStatsData', () {
    test('reads cards_count and due_cards from nested stats (current API)', () {
      final stats = parseDeckCardsStatsData({
        'stats': {
          'cards_count': 12,
          'due_cards': 3,
          'facts_count': 10,
          'unseen_cards': 2,
          'reviewed_cards': 10,
          'hidden_cards': 0,
        },
        'cards': [
          {'id': 'c1'},
          {'id': 'c2'},
        ],
      });

      expect(stats, isNotNull);
      expect(stats!.totalCards, 12);
      expect(stats.dueCards, 3);
    });

    test('reads legacy top-level total_cards and due_cards', () {
      final stats = parseDeckCardsStatsData({
        'total_cards': 20,
        'due_cards': 7,
      });

      expect(stats, isNotNull);
      expect(stats!.totalCards, 20);
      expect(stats.dueCards, 7);
    });

    test('prefers nested stats over legacy top-level fields', () {
      final stats = parseDeckCardsStatsData({
        'total_cards': 999,
        'due_cards': 999,
        'stats': {'cards_count': 12, 'due_cards': 4},
      });

      expect(stats!.totalCards, 12);
      expect(stats.dueCards, 4);
    });

    test('derives due count from cards list when stats omit due_cards', () {
      final stats = parseDeckCardsStatsData({
        'stats': {'cards_count': 3},
        'cards': [
          {'id': 'a', 'due_date': 100, 'hidden': false},
          {'id': 'b', 'due_date': 9999, 'hidden': false},
          {'id': 'c', 'due_date': 50, 'hidden': true},
        ],
      }, nowSec: 500);

      expect(stats!.totalCards, 3);
      expect(stats.dueCards, 1);
    });

    test('returns null for empty or invalid payloads', () {
      expect(parseDeckCardsStatsData(null), isNull);
      expect(parseDeckCardsStatsData(<String, dynamic>{}), isNull);
      expect(parseDeckCardsStatsData('x'), isNull);
    });
  });
}
