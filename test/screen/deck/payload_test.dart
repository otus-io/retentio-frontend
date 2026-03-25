import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/fact_add_composer/payload.dart';

void main() {
  group('AddFactPayload', () {
    test('resolveFieldLabels uses user, deck, then fallback', () {
      final labels = AddFactPayload.resolveFieldLabels(
        entryCount: 3,
        userNamesByRow: ['Custom', null, ''],
        deckFields: ['A', 'B'],
        fallbackForIndex: (n) => 'F$n',
      );
      expect(labels, ['Custom', 'B', 'F3']);
    });

    test('buildEntryJson omits empty strings', () {
      final e = AddFactPayload.buildEntryJson(
        text: '  hi  ',
        imageId: 'img1',
        videoId: '',
        audioId: null,
      );
      expect(e, {'text': 'hi', 'image': 'img1'});
      expect(AddFactPayload.entryHasAnyContent(e), isTrue);
    });

    test('buildFactBody wraps single fact', () {
      final b = AddFactPayload.buildFactBody(
        entries: [
          {'text': 'a'},
        ],
        fields: ['Front'],
      );
      expect(b['facts'], isA<List>());
      final facts = b['facts'] as List;
      expect(facts.length, 1);
      expect((facts.first as Map)['fields'], ['Front']);
    });
  });
}
