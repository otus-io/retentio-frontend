import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/models/card.dart';

void main() {
  group('CardDetail', () {
    group('fromJson', () {
      test('parses full JSON with all fields', () {
        final json = {
          "card": {
            "created_at": 1704067200,
            "due_date": 1704153600,
            "fact_id": "abc1234",
            "hidden": false,
            "id": "xyz12345",
            "last_review": 1704067200,
            "template": [
              [0],
              [1],
            ],
          },
          "urgency": 0.75,
        };
        final detail = CardDetail.fromJson(json);
        expect(detail.card.id, "xyz12345");
        expect(detail.card.factId, "abc1234");
        expect(detail.card.template, [
          [0],
          [1],
        ]);
        expect(detail.card.createdAt, 1704067200);
        expect(detail.card.dueDate, 1704153600);
        expect(detail.card.lastReview, 1704067200);
        expect(detail.card.hidden, false);
        expect(detail.urgency, 0.75);
      });
    });
  });

  group('Card', () {
    group('fromJson', () {
      test('parses full JSON with template', () {
        final json = {
          "created_at": 1704067200,
          "due_date": 1704153600,
          "fact_id": "abc1234",
          "hidden": false,
          "id": "xyz12345",
          "last_review": 1704067200,
          "template": [
            [0],
            [1, 2],
          ],
        };
        final card = Card.fromJson(json);
        expect(card.id, "xyz12345");
        expect(card.factId, "abc1234");
        expect(card.template, [
          [0],
          [1, 2],
        ]);
        expect(card.createdAt, 1704067200);
        expect(card.hidden, false);
      });

      test('uses default template when template is missing', () {
        final json = {
          "created_at": 0,
          "due_date": 0,
          "fact_id": "a",
          "hidden": false,
          "id": "c1",
          "last_review": 0,
        };
        final card = Card.fromJson(json);
        expect(card.template, [
          [0],
          [1],
        ]);
      });

      test('uses default values for missing fields', () {
        final card = Card.fromJson({});
        expect(card.id, '');
        expect(card.factId, '');
        expect(card.template, [
          [0],
          [1],
        ]);
        expect(card.lastReview, 0);
        expect(card.dueDate, 0);
        expect(card.hidden, false);
        expect(card.createdAt, 0);
      });
    });

    group('isDue', () {
      test('returns true when dueDate is in the past and not hidden', () {
        final pastTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
        final card = Card(
          id: 'c1',
          factId: 'a',
          template: [
            [0],
            [1],
          ],
          lastReview: 0,
          dueDate: pastTime,
          hidden: false,
          createdAt: 0,
        );
        expect(card.isDue, true);
      });

      test('returns false when hidden even if dueDate is in the past', () {
        final pastTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
        final card = Card(
          id: 'c1',
          factId: 'a',
          template: [
            [0],
            [1],
          ],
          lastReview: 0,
          dueDate: pastTime,
          hidden: true,
          createdAt: 0,
        );
        expect(card.isDue, false);
      });
    });

    group('isNew', () {
      test('returns true when lastReview is 0', () {
        final card = Card(
          id: 'c1',
          factId: 'a',
          template: [
            [0],
            [1],
          ],
          lastReview: 0,
          dueDate: 0,
          hidden: false,
          createdAt: 0,
        );
        expect(card.isNew, true);
      });

      test('returns false when lastReview is non-zero', () {
        final card = Card(
          id: 'c1',
          factId: 'a',
          template: [
            [0],
            [1],
          ],
          lastReview: 1000,
          dueDate: 0,
          hidden: false,
          createdAt: 0,
        );
        expect(card.isNew, false);
      });
    });

    group('copyWith', () {
      test('copies card with new fact', () {
        final card = Card(
          id: 'c1',
          factId: 'f1',
          template: [
            [0],
            [1],
          ],
          lastReview: 0,
          dueDate: 0,
          hidden: false,
          createdAt: 0,
        );
        final fact = Fact(fields: ['Apple', '苹果'], id: 'f1');
        final updated = card.copyWith(fact: fact);
        expect(updated.fact, fact);
        expect(updated.id, 'c1');
        expect(updated.template, [
          [0],
          [1],
        ]);
      });
    });
  });

  group('Fact', () {
    test('fromJson parses correctly', () {
      final json = {
        "fields": ["Apple", "苹果"],
        "id": "f1",
      };
      final fact = Fact.fromJson(json);
      expect(fact.id, "f1");
      expect(fact.fields, ["Apple", "苹果"]);
    });

    test('fromJson accepts backend entries key', () {
      final json = {
        "entries": ["Hello", "こんにちは"],
        "id": "f2",
      };
      final fact = Fact.fromJson(json);
      expect(fact.id, "f2");
      expect(fact.fields, ["Hello", "こんにちは"]);
    });

    test('fromJson handles empty or missing list', () {
      final fact = Fact.fromJson({'id': 'f3'});
      expect(fact.id, 'f3');
      expect(fact.fields, isEmpty);
    });

    test('toJson serializes correctly (backend uses entries)', () {
      final fact = Fact(fields: ['Apple', '苹果'], id: 'f1');
      final json = fact.toJson();
      expect(json['id'], 'f1');
      expect(json['entries'], ['Apple', '苹果']);
    });
  });

  group('CardStats', () {
    test('fromJson parses total_cards and hidden_count', () {
      final json = {
        'total_cards': 10,
        'hidden_count': 2,
        'hidden_facts': [
          {
            'id': 'f1',
            'entries': ['A', 'B'],
          },
        ],
      };
      final stats = CardStats.fromJson(json);
      expect(stats.totalCards, 10);
      expect(stats.hiddenCount, 2);
      expect(stats.hiddenFacts.length, 1);
      expect(stats.hiddenFacts[0].id, 'f1');
      expect(stats.hiddenFacts[0].fields, ['A', 'B']);
    });

    test('fromJson handles missing fields', () {
      final stats = CardStats.fromJson({});
      expect(stats.totalCards, 0);
      expect(stats.hiddenCount, 0);
      expect(stats.hiddenFacts, isEmpty);
    });
  });
}
