import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/card.dart';

void main() {
  group('CardDetail', () {
    group('fromJson', () {
      test('parses full JSON with all fields', () {
        final json = {
          "card": {
            "back": [
              {
                "field": "Japanese",
                "items": [
                  {"type": "text", "value": "挨拶"},
                  {
                    "type": "audio",
                    "value":
                        "https://api.wordupx.com:8443/api/media/mj8jx4t5kq",
                  },
                  {
                    "type": "image",
                    "value":
                        "https://api.wordupx.com:8443/api/media/04693ndofs",
                  },
                ],
              },
            ],
            "created_at": 1773285984,
            "due_date": 1773208223,
            "fact_id": "8cacjhwa",
            "front": [
              {
                "field": "Chinese",
                "items": [
                  {"type": "text", "value": "打招呼"},
                ],
              },
              {
                "field": "例句",
                "items": [
                  {"type": "text", "value": "挨拶します"},
                ],
              },
            ],
            "hidden": false,
            "id": "unnexyny",
            "last_review": 1773208222,
            "template": [
              [1, 2],
              [0],
            ],
          },
          "urgency": 265878,
        };
        final detail = CardDetail.fromJson(json);
        expect(detail.card?.id, "unnexyny");
      });

      test(
        'parses next-card sibling keys (text, audio, image) into items order',
        () {
          final json = {
            "card": {
              "back": [
                {"field": "Back", "text": "答え"},
              ],
              "created_at": 1,
              "due_date": 2,
              "fact_id": "f1",
              "front": [
                {
                  "field": "Word",
                  "text": "Hello",
                  "audio": "https://api.example.com/api/media/au1",
                  "image": "https://api.example.com/api/media/im1",
                },
              ],
              "hidden": false,
              "id": "c1",
              "last_review": 0,
              "template": [
                [0],
                [1],
              ],
            },
            "urgency": 1.0,
          };
          final detail = CardDetail.fromJson(json);
          final front = detail.card?.front.first;
          expect(front?.text, "Hello");
          expect(front?.field, "Word");

        },
      );
    });

    group('tryFromApiData', () {
      test('returns null when card is empty list (no due card)', () {
        expect(
          CardDetail.fromJson({
            'card': [],
            'meta': {'msg': 'No cards in this deck'},
          }).card,
          isNull,
        );
      });

      test('parses same payload as fromJson when card is an object', () {
        final json = {
          'card': {
            'back': [
              {
                'field': 'Japanese',
                'items': [
                  {'type': 'text', 'value': '挨拶'},
                ],
              },
            ],
            'created_at': 1773285984,
            'due_date': 1773208223,
            'fact_id': '8cacjhwa',
            'front': [
              {
                'field': 'Chinese',
                'items': [
                  {'type': 'text', 'value': '打招呼'},
                ],
              },
            ],
            'hidden': false,
            'id': 'unnexyny',
            'last_review': 1773208222,
            'template': [
              [1, 2],
            ],
          },
          'urgency': 265878,
        };
        final detail = CardDetail.fromJson(json);
        expect(detail, isNotNull);
        expect(detail.card?.id, 'unnexyny');
      });

      test('defaults missing urgency to 0', () {
        final json = {
          'card': {
            'back': [
              {
                'field': 'A',
                'items': [
                  {'type': 'text', 'value': 'x'},
                ],
              },
            ],
            'created_at': 1,
            'due_date': 2,
            'fact_id': 'f',
            'front': [
              {
                'field': 'B',
                'items': [
                  {'type': 'text', 'value': 'y'},
                ],
              },
            ],
            'hidden': false,
            'id': 'id1',
            'last_review': 0,
            'template': [
              [0],
            ],
          },
        };
        final detail = CardDetail.fromJson(json);
        expect(detail, isNotNull);
        expect(detail.urgency, 0);
      });
    });
  });
}
