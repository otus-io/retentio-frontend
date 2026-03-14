import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/card.dart';

void main() {
  group('CardDetail', () {
    group('fromJson', () {
      test('parses full JSON with all fields', () {
        final json =
          {
            "card": {
              "back": [
                {
                  "field": "Japanese",
                  "items": [
                    {
                      "type": "text",
                      "value": "挨拶"
                    },
                    {
                      "type": "audio",
                      "value": "https://api.wordupx.com:8443/api/media/mj8jx4t5kq"
                    },
                    {
                      "type": "image",
                      "value": "https://api.wordupx.com:8443/api/media/04693ndofs"
                    }
                  ]
                }
              ],
              "created_at": 1773285984,
              "due_date": 1773208223,
              "fact_id": "8cacjhwa",
              "front": [
                {
                  "field": "Chinese",
                  "items": [
                    {
                      "type": "text",
                      "value": "打招呼"
                    }
                  ]
                },
                {
                  "field": "例句",
                  "items": [
                    {
                      "type": "text",
                      "value": "挨拶します"
                    }
                  ]
                }
              ],
              "hidden": false,
              "id": "unnexyny",
              "last_review": 1773208222,
              "template": [
                [
                  1,
                  2
                ],
                [
                  0
                ]
              ]
            },
            "urgency": 265878
          }
        ;
        final detail = CardDetail.fromJson(json);
        expect(detail.card.id, "unnexyny");
      });
    });
  });
}
