import 'package:flutter_test/flutter_test.dart';
import 'package:wordupx/models/card.dart';

void main() {
  group('CardDetail', () {
    group('fromJson', () {
      test('parses full JSON with all fields', () {
        final json = {
          'fact_id': 'abc1234',
          'template_index': 2,
          'last_review': 1000,
          'due_date': 2000,
          'hidden': true,
          'min_interval': 5,
          'max_interval': 10,
        };
        final detail = CardDetail.fromJson(json);
        expect(detail.factId, 'abc1234');
        expect(detail.templateIndex, 2);
        expect(detail.lastReview, 1000);
        expect(detail.dueDate, 2000);
        expect(detail.hidden, true);
        expect(detail.minInterval, 5);
        expect(detail.maxInterval, 10);
      });

      test('uses default values for missing fields', () {
        final detail = CardDetail.fromJson({});
        expect(detail.factId, '');
        expect(detail.templateIndex, 0);
        expect(detail.lastReview, 0);
        expect(detail.dueDate, 0);
        expect(detail.hidden, false);
        expect(detail.minInterval, 0);
        expect(detail.maxInterval, 0);
      });

      test('uses null coalescing for null values', () {
        final json = {
          'fact_id': null,
          'template_index': null,
          'last_review': null,
          'due_date': null,
          'hidden': null,
          'min_interval': null,
          'max_interval': null,
        };
        final detail = CardDetail.fromJson(json);
        expect(detail.factId, '');
        expect(detail.templateIndex, 0);
        expect(detail.lastReview, 0);
        expect(detail.dueDate, 0);
        expect(detail.hidden, false);
        expect(detail.minInterval, 0);
        expect(detail.maxInterval, 0);
      });
    });

    group('toJson', () {
      test('serializes to correct format', () {
        final detail = CardDetail(
          factId: 'abc1234',
          templateIndex: 2,
          lastReview: 1000,
          dueDate: 2000,
          hidden: true,
          minInterval: 5,
          maxInterval: 10,
        );
        final json = detail.toJson();
        expect(json['fact_id'], 'abc1234');
        expect(json['template_index'], 2);
        expect(json['last_review'], 1000);
        expect(json['due_date'], 2000);
        expect(json['hidden'], true);
        expect(json['min_interval'], 5);
        expect(json['max_interval'], 10);
      });
    });

    group('isDue', () {
      test('returns true when dueDate is in the past and not hidden', () {
        final pastTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
        final detail = CardDetail(
          factId: 'a',
          templateIndex: 0,
          lastReview: 0,
          dueDate: pastTime,
          hidden: false,
          minInterval: 0,
          maxInterval: 0,
        );
        expect(detail.isDue, true);
      });

      test('returns false when hidden even if dueDate is in the past', () {
        final pastTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
        final detail = CardDetail(
          factId: 'a',
          templateIndex: 0,
          lastReview: 0,
          dueDate: pastTime,
          hidden: true,
          minInterval: 0,
          maxInterval: 0,
        );
        expect(detail.isDue, false);
      });

      test('returns false when dueDate is in the future', () {
        final futureTime =
            (DateTime.now().millisecondsSinceEpoch ~/ 1000) + 3600;
        final detail = CardDetail(
          factId: 'a',
          templateIndex: 0,
          lastReview: 0,
          dueDate: futureTime,
          hidden: false,
          minInterval: 0,
          maxInterval: 0,
        );
        expect(detail.isDue, false);
      });
    });

    group('isNew', () {
      test('returns true when lastReview is 0', () {
        final detail = CardDetail(
          factId: 'a',
          templateIndex: 0,
          lastReview: 0,
          dueDate: 0,
          hidden: false,
          minInterval: 0,
          maxInterval: 0,
        );
        expect(detail.isNew, true);
      });

      test('returns false when lastReview is non-zero', () {
        final detail = CardDetail(
          factId: 'a',
          templateIndex: 0,
          lastReview: 1000,
          dueDate: 0,
          hidden: false,
          minInterval: 0,
          maxInterval: 0,
        );
        expect(detail.isNew, false);
      });
    });
  });

  group('Card', () {
    final cardDetail = CardDetail(
      factId: 'a',
      templateIndex: 0,
      lastReview: 0,
      dueDate: 0,
      hidden: false,
      minInterval: 0,
      maxInterval: 0,
    );

    group('fromJson', () {
      test('parses simplified JSON (flat CardDetail fields)', () {
        final json = {
          'fact_id': 'abc1234',
          'template_index': 0,
          'last_review': 0,
          'due_date': 0,
          'hidden': false,
          'min_interval': 10,
          'max_interval': 365,
          'card_index': 5,
          'urgency': 1.5,
        };
        final card = Card.fromJson(json);
        expect(card.card.factId, 'abc1234');
        expect(card.cardIndex, 5);
        expect(card.urgency, 1.5);
        expect(card.minInterval, 10);
        expect(card.maxInterval, 365);
      });

      test('parses full JSON with nested card object', () {
        final json = {
          'card': {
            'fact_id': 'def5678',
            'template_index': 1,
            'last_review': 500,
            'due_date': 1000,
            'hidden': false,
            'min_interval': 20,
            'max_interval': 500,
          },
          'card_index': 10,
          'urgency': 2.0,
        };
        final card = Card.fromJson(json);
        expect(card.card.factId, 'def5678');
        expect(card.card.lastReview, 500);
        expect(card.cardIndex, 10);
        expect(card.urgency, 2.0);
        expect(card.minInterval, 20);
        expect(card.maxInterval, 500);
      });

      test('uses defaults for missing fields', () {
        final json = {
          'fact_id': 'a',
          'template_index': 0,
          'last_review': 0,
          'due_date': 0,
          'hidden': false,
          'min_interval': 0,
          'max_interval': 0,
        };
        final card = Card.fromJson(json);
        expect(card.minInterval, 0);
        expect(card.maxInterval, 0);
        expect(card.urgency, 0.0);
      });
    });

    group('toJson', () {
      test('serializes to correct format with nested card', () {
        final card = Card(
          card: cardDetail,
          cardIndex: 5,
          maxInterval: 365,
          minInterval: 1,
          urgency: 1.0,
        );
        final json = card.toJson();
        expect(json.containsKey('card'), true);
        expect(json['card_index'], 5);
        expect(json['urgency'], 1.0);
      });
    });

    group('isDue, isNew, isHidden', () {
      test('isDue delegates to card.isDue', () {
        final pastTime = (DateTime.now().millisecondsSinceEpoch ~/ 1000) - 3600;
        final dueDetail = CardDetail(
          factId: 'a',
          templateIndex: 0,
          lastReview: 0,
          dueDate: pastTime,
          hidden: false,
          minInterval: 0,
          maxInterval: 0,
        );
        final card = Card(
          card: dueDetail,
          cardIndex: 0,
          maxInterval: 365,
          minInterval: 1,
          urgency: 1.0,
        );
        expect(card.isDue, true);
      });

      test('isNew delegates to card.isNew', () {
        final newDetail = CardDetail(
          factId: 'a',
          templateIndex: 0,
          lastReview: 0,
          dueDate: 0,
          hidden: false,
          minInterval: 0,
          maxInterval: 0,
        );
        final card = Card(
          card: newDetail,
          cardIndex: 0,
          maxInterval: 365,
          minInterval: 1,
          urgency: 1.0,
        );
        expect(card.isNew, true);
      });

      test('isHidden delegates to card.hidden', () {
        final hiddenDetail = CardDetail(
          factId: 'a',
          templateIndex: 0,
          lastReview: 0,
          dueDate: 0,
          hidden: true,
          minInterval: 0,
          maxInterval: 0,
        );
        final card = Card(
          card: hiddenDetail,
          cardIndex: 0,
          maxInterval: 365,
          minInterval: 1,
          urgency: 1.0,
        );
        expect(card.isHidden, true);
      });
    });
  });
}
