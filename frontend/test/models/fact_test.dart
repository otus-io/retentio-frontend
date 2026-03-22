import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/fact.dart';

void main() {
  group('FactEntry', () {
    test('fromJson fills all media fields with defaults for missing keys', () {
      final e = FactEntry.fromJson({'text': 'hello'});
      expect(e.text, 'hello');
      expect(e.audio, '');
      expect(e.image, '');
      expect(e.video, '');
    });

    test('fromJson parses all keys', () {
      final e = FactEntry.fromJson({
        'text': 't',
        'audio': 'a',
        'image': 'i',
        'video': 'v',
      });
      expect(e.text, 't');
      expect(e.audio, 'a');
      expect(e.image, 'i');
      expect(e.video, 'v');
    });

    test('toJson includes text always; media keys only when non-empty', () {
      expect(FactEntry(text: 'x').toJson(), {'text': 'x'});
      expect(FactEntry(text: 'x', audio: 'https://a').toJson(), {
        'text': 'x',
        'audio': 'https://a',
      });
    });

    test('copyWithText updates only text', () {
      final a = FactEntry(text: 'a', audio: 'keep');
      final b = a.copyWithText('b');
      expect(b.text, 'b');
      expect(b.audio, 'keep');
    });
  });

  group('Fact', () {
    test('fromJson parses id, entries, and fields', () {
      final f = Fact.fromJson({
        'id': 'f1',
        'entries': [
          {'text': 'one', 'audio': ''},
          {'text': 'two'},
        ],
        'fields': ['A', 'B'],
      });
      expect(f.id, 'f1');
      expect(f.entries.length, 2);
      expect(f.entries[0].text, 'one');
      expect(f.fields, ['A', 'B']);
    });

    test('fromJson uses empty lists when entries or fields are not lists', () {
      final f = Fact.fromJson({'id': 'x', 'entries': 'bad', 'fields': 1});
      expect(f.entries, isEmpty);
      expect(f.fields, isEmpty);
    });

    test(
      'toUpdateBody always includes entries; fields only when lengths match',
      () {
        final ok = Fact(
          id: '1',
          entries: [
            FactEntry(text: 'a'),
            FactEntry(text: 'b'),
          ],
          fields: ['F1', 'F2'],
        );
        final body = ok.toUpdateBody();
        expect(body['entries'], isA<List<dynamic>>());
        expect(body['fields'], ['F1', 'F2']);

        final mismatch = Fact(
          id: '1',
          entries: [FactEntry(text: 'a')],
          fields: ['too', 'many'],
        );
        expect(mismatch.toUpdateBody().containsKey('fields'), false);
      },
    );

    test('withMergedTexts replaces text per slot and preserves media', () {
      final fact = Fact(
        id: 'id',
        entries: [
          FactEntry(text: 'old', audio: 'https://a'),
          FactEntry(text: 'old2', image: 'https://i'),
        ],
        fields: ['x', 'y'],
      );
      final next = fact.withMergedTexts(['n1', 'n2']);
      expect(next.entries[0].text, 'n1');
      expect(next.entries[0].audio, 'https://a');
      expect(next.entries[1].text, 'n2');
      expect(next.entries[1].image, 'https://i');
      expect(next.fields, fact.fields);
    });

    test('withMergedTexts throws when text count does not match entries', () {
      final fact = Fact(
        id: 'id',
        entries: [FactEntry(text: 'a')],
        fields: ['f'],
      );
      expect(() => fact.withMergedTexts([]), throwsArgumentError);
      expect(() => fact.withMergedTexts(['a', 'b']), throwsArgumentError);
    });
  });
}
