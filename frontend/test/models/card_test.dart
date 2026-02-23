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
            "template_index": 0,
          },
          "urgency": 0.75,
        };
        final detail = CardDetail.fromJson(json);
        expect(detail.card.id, "xyz12345");
        expect(detail.urgency, 0.75);

      });
    });
  });
}
