import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/card.dart';

void main() {
  group('DeckStudy hidden-card policy input', () {
    test('CardDetail.hidden is parsed and available for repository filtering', () {
      final visible = CardDetail.fromJson({
        'urgency': 0.5,
        'card': {
          'id': 'card-visible',
          'fact_id': 'fact-1',
          'hidden': false,
          'created_at': 1,
          'due_date': 100,
          'last_review': 10,
          'template': [
            [0],
            [1],
          ],
          'front': [
            {
              'field': 'Front',
              'items': [
                {'type': 'text', 'value': 'Hello'},
              ],
            },
          ],
          'back': [
            {
              'field': 'Back',
              'items': [
                {'type': 'text', 'value': 'World'},
              ],
            },
          ],
        },
      });

      final hidden = CardDetail.fromJson({
        'urgency': 0.5,
        'card': {
          'id': 'card-hidden',
          'fact_id': 'fact-1',
          'hidden': true,
          'created_at': 1,
          'due_date': 100,
          'last_review': 10,
          'template': [
            [0],
            [1],
          ],
          'front': [
            {
              'field': 'Front',
              'items': [
                {'type': 'text', 'value': 'Hello'},
              ],
            },
          ],
          'back': [
            {
              'field': 'Back',
              'items': [
                {'type': 'text', 'value': 'World'},
              ],
            },
          ],
        },
      });

      expect(visible.card.hidden, isFalse);
      expect(hidden.card.hidden, isTrue);
    });
  });
}
