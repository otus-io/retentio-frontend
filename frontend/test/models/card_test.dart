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

  // group('CardSlot', () {
  //   group('fromJson', () {
  //     test('parses legacy items array with field', () {
  //       final slot = CardSlot.fromJson({
  //         'field': 'Gloss',
  //         'items': [
  //           {'type': 'text', 'value': 'hello'},
  //           {'type': 'audio', 'value': 'https://x/a'},
  //         ],
  //       });
  //       expect(slot.field, 'Gloss');
  //       expect(slot.text, 'text');
  //       expect(slot.items[0].value, 'hello');
  //       expect(slot.items[1].type, 'audio');
  //     });
  //
  //     test('defaults field to Text when missing', () {
  //       final slot = CardSlot.fromJson({
  //         'items': [
  //           {'type': 'text', 'value': 'only'},
  //         ],
  //       });
  //       expect(slot.field, 'Text');
  //     });
  //
  //     test(
  //       'synthesizes items from flat text, audio, image, video keys in order',
  //       () {
  //         final slot = CardSlot.fromJson({
  //           'field': 'Rich',
  //           'text': 't',
  //           'audio': 'a',
  //           'image': 'i',
  //           'video': 'v',
  //         });
  //         expect(slot.items.length, 4);
  //         expect(slot.items.map((e) => e.type).toList(), [
  //           'text',
  //           'audio',
  //           'image',
  //           'video',
  //         ]);
  //         expect(slot.items[3].value, 'v');
  //       },
  //     );
  //
  //     test('ignores empty strings in flat format', () {
  //       final slot = CardSlot.fromJson({
  //         'field': 'X',
  //         'text': '',
  //         'audio': 'https://a',
  //       });
  //       expect(slot.items.length, 1);
  //       expect(slot.items.single.type, 'audio');
  //     });
  //
  //     test('adds empty text item when no content', () {
  //       final slot = CardSlot.fromJson({'field': 'Empty'});
  //       expect(slot.items.length, 1);
  //       expect(slot.items.single.type, 'text');
  //       expect(slot.items.single.value, '');
  //     });
  //   });
  //
  //   test('toJson round-trips with fromJson (legacy shape)', () {
  //     final original = CardSlot(
  //       field: 'Lemma',
  //       items: [
  //         Item(type: 'text', value: 'run'),
  //         Item(type: 'image', value: 'https://img'),
  //       ],
  //     );
  //     final decoded = CardSlot.fromJson(
  //       Map<String, dynamic>.from(original.toJson()),
  //     );
  //     expect(decoded.field, original.field);
  //     expect(decoded.items.length, original.items.length);
  //     expect(decoded.items[1].value, 'https://img');
  //   });
  //
  //   test('copyWith updates only provided fields', () {
  //     final a = CardSlot(
  //       field: 'A',
  //       items: [Item(type: 'text', value: '1')],
  //     );
  //     final b = a.copyWith(field: 'B');
  //     expect(b.field, 'B');
  //     expect(b.items, same(a.items));
  //   });
  // });

  group('Card CardSlot integration', () {
    test('front and back deserialize to CardSlot lists', () {
      final card = Card.fromJson({
        'back': [
          {
            'field': 'Answer',
            'items': [
              {'type': 'text', 'value': 'y'},
            ],
          },
        ],
        'created_at': 0,
        'due_date': 0,
        'fact_id': 'f',
        'front': [
          {
            'field': 'Question',
            'items': [
              {'type': 'text', 'value': 'x'},
            ],
          },
        ],
        'hidden': false,
        'id': 'id',
        'last_review': 0,
        'template': <List<int>>[],
      });
      expect(card.front, isA<List<CardSlot>>());
      expect(card.back, isA<List<CardSlot>>());
      expect(card.front.single, isA<CardSlot>());
      expect(card.front.single.field, 'Question');
      expect(card.back.single.field, 'Answer');
    });
  });
}
