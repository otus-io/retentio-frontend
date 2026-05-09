import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/screen/deck/fact_add_composer/payload.dart';

void main() {
  group('AddFactPayload', () {
    test('deckColumnLabel uses deck then fallback', () {
      expect(
        AddFactPayload.deckColumnLabel(
          columnIndex: 0,
          deckFields: ['A', 'B'],
          fallbackForIndex: (n) => 'F$n',
        ),
        'A',
      );
      expect(
        AddFactPayload.deckColumnLabel(
          columnIndex: 1,
          deckFields: ['A', 'B'],
          fallbackForIndex: (n) => 'F$n',
        ),
        'B',
      );
      expect(
        AddFactPayload.deckColumnLabel(
          columnIndex: 2,
          deckFields: ['A', 'B'],
          fallbackForIndex: (n) => 'F$n',
        ),
        'F3',
      );
      expect(
        AddFactPayload.deckColumnLabel(
          columnIndex: 0,
          deckFields: ['  ', 'B'],
          fallbackForIndex: (n) => 'F$n',
        ),
        'F1',
      );
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

    test('buildEntryJson includes audio id when set', () {
      final e = AddFactPayload.buildEntryJson(text: '', audioId: 'aud-99');
      expect(e, {'audio': 'aud-99'});
      expect(AddFactPayload.entryHasAnyContent(e), isTrue);
    });

    test('buildEntryJson omits blank audio id', () {
      final e = AddFactPayload.buildEntryJson(text: 'x', audioId: '  ');
      expect(e.containsKey('audio'), isFalse);
      expect(e, {'text': 'x'});
    });

    test('buildFactBody wraps single fact without per-fact fields', () {
      final b = AddFactPayload.buildFactBody(
        entries: [
          {'text': 'a'},
        ],
      );
      expect(b['facts'], isA<List>());
      final facts = b['facts'] as List;
      expect(facts.length, 1);
      final first = facts.first as Map;
      expect(first.containsKey('fields'), isFalse);
      expect(first['entries'], [
        {'text': 'a'},
      ]);
    });
  });
}
