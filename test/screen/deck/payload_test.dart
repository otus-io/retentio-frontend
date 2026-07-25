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

    test('buildFactBody includes tags when tagNames is non-empty', () {
      final b = AddFactPayload.buildFactBody(
        entries: [
          {'text': 'a'},
        ],
        tagNames: ['Flutter', 'Dart'],
      );
      final first = (b['facts'] as List).first as Map;
      expect(first['tags'], ['Flutter', 'Dart']);
    });

    test('buildFactBody omits tags key when tagNames is null', () {
      final b = AddFactPayload.buildFactBody(
        entries: [
          {'text': 'a'},
        ],
      );
      final first = (b['facts'] as List).first as Map;
      expect(first.containsKey('tags'), isFalse);
    });

    test('buildFactBody omits tags key when tagNames is empty', () {
      final b = AddFactPayload.buildFactBody(
        entries: [
          {'text': 'a'},
        ],
        tagNames: const [],
      );
      final first = (b['facts'] as List).first as Map;
      expect(first.containsKey('tags'), isFalse);
    });

    test('buildFactBody includes tag_ids when provided', () {
      final b = AddFactPayload.buildFactBody(
        entries: [
          {'text': 'a'},
        ],
        tagIds: ['id1', 'id2'],
      );
      final first = (b['facts'] as List).first as Map;
      expect(first['tag_ids'], ['id1', 'id2']);
      expect(first.containsKey('tags'), isFalse);
    });

    test('buildFactBody prefers tag_ids over tagNames', () {
      final b = AddFactPayload.buildFactBody(
        entries: [
          {'text': 'a'},
        ],
        tagIds: ['id1'],
        tagNames: ['Name'],
      );
      final first = (b['facts'] as List).first as Map;
      expect(first['tag_ids'], ['id1']);
      expect(first.containsKey('tags'), isFalse);
    });
  });
}
