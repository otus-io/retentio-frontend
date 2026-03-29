import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/transcript_sync.dart';

void main() {
  group('TranscriptSync', () {
    test('tryParse accepts retentio-transcript-sync with words', () {
      const raw = '''
{"format":"retentio-transcript-sync","version":2,"words":[
  {"word":"ab","start":0.0,"end":0.5},
  {"word":"cd","start":0.5,"end":1.0}
]}''';
      final s = TranscriptSync.tryParse(raw);
      expect(s, isNotNull);
      expect(s!.words.length, 2);
      expect(s.words[0].word, 'ab');
      expect(s.words[1].end, 1.0);
      expect(s.annotatedSourceText, isNull);
    });

    test('tryParse stores text field as annotatedSourceText', () {
      const raw = '''
{"format":"retentio-transcript-sync","text":"[[皆|みな]]","words":[
  {"word":"皆","start":0.0,"end":0.5}
]}''';
      final s = TranscriptSync.tryParse(raw);
      expect(s, isNotNull);
      expect(s!.annotatedSourceText, '[[皆|みな]]');
    });

    test('tryParse returns null for wrong format', () {
      expect(TranscriptSync.tryParse('{"format":"other","words":[]}'), isNull);
    });

    test('tryParse returns null when words list is empty', () {
      expect(
        TranscriptSync.tryParse(
          '{"format":"retentio-transcript-sync","words":[]}',
        ),
        isNull,
      );
    });

    test('tryParse skips word entries missing string word', () {
      const raw =
          '{"format":"retentio-transcript-sync","words":[{"word":1,"start":0,"end":1}]}';
      expect(TranscriptSync.tryParse(raw), isNull);
    });

    test('wordIndexAt returns last word with start <= t', () {
      final s = TranscriptSync(
        words: const [
          TranscriptWord(word: 'a', start: 0, end: 0.2),
          TranscriptWord(word: 'b', start: 0.5, end: 1.0),
        ],
      );
      expect(s.wordIndexAt(-0.1), -1);
      expect(s.wordIndexAt(0), 0);
      expect(s.wordIndexAt(0.35), 0);
      expect(s.wordIndexAt(0.5), 1);
      expect(s.wordIndexAt(0.99), 1);
    });

    test('seekMsNextFrom jumps to following word start', () {
      final s = TranscriptSync(
        words: const [
          TranscriptWord(word: 'a', start: 0, end: 0.2),
          TranscriptWord(word: 'b', start: 0.5, end: 1.0),
        ],
      );
      expect(s.seekMsNextFrom(0), 500);
      expect(s.seekMsNextFrom(100), 500);
      expect(s.seekMsNextFrom(600), isNull);
    });

    test('seekMsPrevFrom goes to word start or previous word', () {
      final s = TranscriptSync(
        words: const [
          TranscriptWord(word: 'a', start: 0, end: 0.2),
          TranscriptWord(word: 'b', start: 0.5, end: 1.0),
        ],
      );
      expect(s.seekMsPrevFrom(600), 500);
      expect(s.seekMsPrevFrom(520), 0);
      expect(s.seekMsPrevFrom(50), 0);
    });

    test('seekMsNextFrom and seekMsPrevFrom on empty words', () {
      final s = TranscriptSync(words: const []);
      expect(s.seekMsNextFrom(0), isNull);
      expect(s.seekMsPrevFrom(100), 0);
    });

    test('seekMsNextFrom respects slop within same word start', () {
      final s = TranscriptSync(
        words: const [
          TranscriptWord(word: 'a', start: 0, end: 1),
          TranscriptWord(word: 'b', start: 0.5, end: 2),
        ],
      );
      expect(s.seekMsNextFrom(480), isNull);
    });
  });
}
