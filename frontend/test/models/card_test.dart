import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/card.dart';

void main() {
  group('CardDetail', () {
    group('fromJson', () {
      test('parses full JSON with all fields', () {
        final json = {
          "card": {
            "back": [
              {"field": "Japanese", "type": "text", "value": "挨拶"},
              {"field": "audio", "type": "audio", "value": "204bfe1fwg"},
            ],
            "created_at": 1772370463,
            "due_date": 1772292702,
            "fact_id": "88ri5b2g",
            "front": [
              {"field": "Chinese", "type": "text", "value": "打招呼"},
              {"field": "", "type": "text", "value": "挨拶します"},
              {"field": "img", "type": "image", "value": "43b0jpd03v"},
            ],
            "hidden": false,
            "id": "xyz12345",
            "last_review": 1772292701,
            "template": [
              [2, 3, 4],
              [0, 1],
            ],
          },
        };
        final detail = CardDetail.fromJson(json);
        expect(detail.card.id, "xyz12345");
      });
    });
  });
}
