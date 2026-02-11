import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/models/card.dart';

void main() {
  group('CardDetail', () {
    group('fromJson', () {
      test('parses full JSON with all fields', () {
        final json = {
          'fact_index': 1,
          'template_index': 2,
          'last_review': 1000,
          'due_date': 2000,
          'hidden': true,
          'min_calculation': 5,
          'max_calculation': 10,
        };
        final detail = CardDetail.fromJson(json);
        expect(detail.factIndex, 1);
        expect(detail.templateIndex, 2);
        expect(detail.lastReview, 1000);
        expect(detail.dueDate, 2000);
        expect(detail.hidden, true);
        expect(detail.minCalculation, 5);
        expect(detail.maxCalculation, 10);
      });

      test('uses default values for missing fields', () {
        final detail = CardDetail.fromJson({});
        expect(detail.factIndex, 0);
        expect(detail.templateIndex, 0);
        expect(detail.lastReview, 0);
        expect(detail.dueDate, 0);
        expect(detail.hidden, false);
        expect(detail.minCalculation, 0);
        expect(detail.maxCalculation, 0);
      });

      test('uses null coalescing for null values', () {
        final json = {
          'fact_index': null,
          'template_index': null,
          'last_review': null,
          'due_date': null,
          'hidden': null,
          'min_calculation': null,
          'max_calculation': null,
        };
        final detail = CardDetail.fromJson(json);
        expect(detail.factIndex, 0);
        expect(detail.templateIndex, 0);
        expect(detail.lastReview, 0);
        expect(detail.dueDate, 0);
        expect(detail.hidden, false);
        expect(detail.minCalculation, 0);
        expect(detail.maxCalculation, 0);
      });
    });

    group('toJson', () {
      test('serializes to correct format', () {
        final detail = CardDetail(
          factIndex: 1,
          templateIndex: 2,
          lastReview: 1000,
          dueDate: 2000,
          hidden: true,
          minCalculation: 5,
          maxCalculation: 10,
        );
        final json = detail.toJson();
        expect(json['fact_index'], 1);
        expect(json['template_index'], 2);
        expect(json['last_review'], 1000);
        expect(json['due_date'], 2000);
        expect(json['hidden'], true);
        expect(json['min_calculation'], 5);
        expect(json['max_calculation'], 10);
      });
    });

    group('isDue', () {
      test('returns true when dueDate is in the past and not hidden', () {
        final pastTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
        final detail = CardDetail(
          factIndex: 0,
          templateIndex: 0,
          lastReview: 0,
          dueDate: pastTime,
          hidden: false,
          minCalculation: 0,
          maxCalculation: 0,
        );
        expect(detail.isDue, true);
      });

      test('returns false when hidden even if dueDate is in the past', () {
        final pastTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
        final detail = CardDetail(
          factIndex: 0,
          templateIndex: 0,
          lastReview: 0,
          dueDate: pastTime,
          hidden: true,
          minCalculation: 0,
          maxCalculation: 0,
        );
        expect(detail.isDue, false);
      });

      test('returns false when dueDate is in the future', () {
        final futureTime =
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
        final detail = CardDetail(
          factIndex: 0,
          templateIndex: 0,
          lastReview: 0,
          dueDate: futureTime,
          hidden: false,
          minCalculation: 0,
          maxCalculation: 0,
        );
        expect(detail.isDue, false);
      });
    });

    group('isNew', () {
      test('returns true when lastReview is 0', () {
        final detail = CardDetail(
          factIndex: 0,
          templateIndex: 0,
          lastReview: 0,
          dueDate: 0,
          hidden: false,
          minCalculation: 0,
          maxCalculation: 0,
        );
        expect(detail.isNew, true);
      });

      test('returns false when lastReview is non-zero', () {
        final detail = CardDetail(
          factIndex: 0,
          templateIndex: 0,
          lastReview: 1000,
          dueDate: 0,
          hidden: false,
          minCalculation: 0,
          maxCalculation: 0,
        );
        expect(detail.isNew, false);
      });
    });
  });

  group('Card', () {
    final cardDetail = CardDetail(
      factIndex: 0,
      templateIndex: 0,
      lastReview: 0,
      dueDate: 0,
      hidden: false,
      minCalculation: 0,
      maxCalculation: 0,
    );

    group('fromJson', () {
      test('parses simplified JSON (flat CardDetail fields)', () {
        final json = {
          'fact_index': 1,
          'template_index': 0,
          'last_review': 0,
          'due_date': 0,
          'hidden': false,
          'min_calculation': 0,
          'max_calculation': 0,
          'card_index': 5,
          'def_interval': 1,
          'fact': ['front', 'back'],
          'hidden_cards': 0,
          'max_interval': 365,
          'min_interval': 1,
          'template': [0, 1],
          'urgency': 1.5,
        };
        final card = Card.fromJson(json);
        expect(card.card.factIndex, 1);
        expect(card.cardIndex, 5);
        expect(card.fact, ['front', 'back']);
        expect(card.urgency, 1.5);
      });

      test('parses full JSON with nested card object', () {
        final json = {
          'card': {
            'fact_index': 2,
            'template_index': 1,
            'last_review': 500,
            'due_date': 1000,
            'hidden': false,
            'min_calculation': 0,
            'max_calculation': 0,
          },
          'card_index': 10,
          'def_interval': 1,
          'fact': ['question', 'answer'],
          'hidden_cards': 2,
          'max_interval': 365,
          'min_interval': 1,
          'template': [0],
          'urgency': 2.0,
        };
        final card = Card.fromJson(json);
        expect(card.card.factIndex, 2);
        expect(card.card.lastReview, 500);
        expect(card.cardIndex, 10);
        expect(card.fact, ['question', 'answer']);
        expect(card.hiddenCards, 2);
        expect(card.urgency, 2.0);
      });

      test('uses empty list for missing fact and template', () {
        final json = {
          'fact_index': 0,
          'template_index': 0,
          'last_review': 0,
          'due_date': 0,
          'hidden': false,
          'min_calculation': 0,
          'max_calculation': 0,
        };
        final card = Card.fromJson(json);
        expect(card.fact, isEmpty);
        expect(card.template, isEmpty);
      });

      test('handles fact with non-string elements by converting to string', () {
        final json = {
          'fact_index': 0,
          'template_index': 0,
          'last_review': 0,
          'due_date': 0,
          'hidden': false,
          'min_calculation': 0,
          'max_calculation': 0,
          'fact': [123, 456],
        };
        final card = Card.fromJson(json);
        expect(card.fact, ['123', '456']);
      });
    });

    group('toJson', () {
      test('serializes to correct format with nested card', () {
        final card = Card(
          card: cardDetail,
          cardIndex: 5,
          defInterval: 1,
          fact: ['a', 'b'],
          hiddenCards: 0,
          maxInterval: 365,
          minInterval: 1,
          template: [0, 1],
          urgency: 1.0,
        );
        final json = card.toJson();
        expect(json.containsKey('card'), true);
        expect(json['card_index'], 5);
        expect(json['fact'], ['a', 'b']);
        expect(json['urgency'], 1.0);
      });
    });

    group('front and back getters', () {
      test('front returns first fact when fact is not empty', () {
        final card = Card(
          card: cardDetail,
          cardIndex: 0,
          defInterval: 1,
          fact: ['front text', 'back text'],
          hiddenCards: 0,
          maxInterval: 365,
          minInterval: 1,
          template: [0],
          urgency: 1.0,
        );
        expect(card.front, 'front text');
      });

      test('front returns empty string when fact is empty', () {
        final card = Card(
          card: cardDetail,
          cardIndex: 0,
          defInterval: 1,
          fact: [],
          hiddenCards: 0,
          maxInterval: 365,
          minInterval: 1,
          template: [0],
          urgency: 1.0,
        );
        expect(card.front, '');
      });

      test('back returns second fact when fact has more than one element', () {
        final card = Card(
          card: cardDetail,
          cardIndex: 0,
          defInterval: 1,
          fact: ['front', 'back'],
          hiddenCards: 0,
          maxInterval: 365,
          minInterval: 1,
          template: [0],
          urgency: 1.0,
        );
        expect(card.back, 'back');
      });

      test('back returns empty string when fact has only one element', () {
        final card = Card(
          card: cardDetail,
          cardIndex: 0,
          defInterval: 1,
          fact: ['only one'],
          hiddenCards: 0,
          maxInterval: 365,
          minInterval: 1,
          template: [0],
          urgency: 1.0,
        );
        expect(card.back, '');
      });
    });

    group('isDue, isNew, isHidden', () {
      test('isDue delegates to card.isDue', () {
        final pastTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
        final dueDetail = CardDetail(
          factIndex: 0,
          templateIndex: 0,
          lastReview: 0,
          dueDate: pastTime,
          hidden: false,
          minCalculation: 0,
          maxCalculation: 0,
        );
        final card = Card(
          card: dueDetail,
          cardIndex: 0,
          defInterval: 1,
          fact: [],
          hiddenCards: 0,
          maxInterval: 365,
          minInterval: 1,
          template: [0],
          urgency: 1.0,
        );
        expect(card.isDue, true);
      });

      test('isNew delegates to card.isNew', () {
        final newDetail = CardDetail(
          factIndex: 0,
          templateIndex: 0,
          lastReview: 0,
          dueDate: 0,
          hidden: false,
          minCalculation: 0,
          maxCalculation: 0,
        );
        final card = Card(
          card: newDetail,
          cardIndex: 0,
          defInterval: 1,
          fact: [],
          hiddenCards: 0,
          maxInterval: 365,
          minInterval: 1,
          template: [0],
          urgency: 1.0,
        );
        expect(card.isNew, true);
      });

      test('isHidden delegates to card.hidden', () {
        final hiddenDetail = CardDetail(
          factIndex: 0,
          templateIndex: 0,
          lastReview: 0,
          dueDate: 0,
          hidden: true,
          minCalculation: 0,
          maxCalculation: 0,
        );
        final card = Card(
          card: hiddenDetail,
          cardIndex: 0,
          defInterval: 1,
          fact: [],
          hiddenCards: 0,
          maxInterval: 365,
          minInterval: 1,
          template: [0],
          urgency: 1.0,
        );
        expect(card.isHidden, true);
      });
    });
  });
}
