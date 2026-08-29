import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/fact.dart';
import 'package:retentio/models/fact_quality.dart';

void main() {
  group('FactQuality.fromJson', () {
    test('parses entry indexes and aspects', () {
      final quality = FactQuality.fromJson({
        'entries': {
          '0': {
            'text': {'score': 10, 'model': 'human'},
            'audio': {'score': 3, 'model': 'elevenlabs'},
          },
          '2': {
            'text': {'score': '4', 'model': 'claude'},
          },
        },
      });

      expect(quality.entries.keys, containsAll(<int>[0, 2]));
      expect(quality.aspectsAt(0)['text']!.score, 10);
      expect(quality.aspectsAt(0)['text']!.isHuman, isTrue);
      expect(quality.aspectsAt(0)['audio']!.isHuman, isFalse);
      expect(quality.aspectsAt(2)['text']!.score, 4);
      expect(quality.aspectsAt(1), isEmpty);
    });

    test('skips malformed indexes, aspects, scores and models', () {
      final quality = FactQuality.fromJson({
        'entries': {
          'x': {
            'text': {'score': 10, 'model': 'human'},
          },
          '-1': {
            'text': {'score': 10, 'model': 'human'},
          },
          '1': 'not-a-map',
          '2': {
            'text': 'not-a-map',
            'audio': {'score': null, 'model': 'human'},
          },
          '3': {
            'text': {'score': 5, 'model': ''},
          },
          '4': {
            'text': {'score': 2.6, 'model': 'claude'},
          },
        },
      });

      expect(quality.entries.keys, [4]);
      expect(quality.aspectsAt(4)['text']!.score, 2);
    });

    test('tolerates a missing or non-map entries key', () {
      expect(FactQuality.fromJson({}).entries, isEmpty);
      expect(FactQuality.fromJson({'entries': 7}).entries, isEmpty);
    });

    test('aspect toJson keeps score and model', () {
      const aspect = FactQualityAspect(score: 10, model: 'human');
      expect(aspect.toJson(), {'score': 10, 'model': 'human'});
    });
  });

  group('FactQualityStats.fromJson', () {
    test('reads counters and defaults missing ones to zero', () {
      final stats = FactQualityStats.fromJson({
        'verified_aspects': 12,
        'total_aspects': '40',
      });
      expect(stats.verifiedAspects, 12);
      expect(stats.totalAspects, 40);

      final empty = FactQualityStats.fromJson({'verified_aspects': <int>[]});
      expect(empty.verifiedAspects, 0);
      expect(empty.totalAspects, 0);
    });

    test('reads the resume cursor when present', () {
      final stats = FactQualityStats.fromJson({'last_fact_id': 'fact-9'});
      expect(stats.lastFactId, 'fact-9');
    });

    test('leaves the cursor null when missing or empty', () {
      expect(FactQualityStats.fromJson({}).lastFactId, isNull);
      expect(
        FactQualityStats.fromJson({'last_fact_id': ''}).lastFactId,
        isNull,
      );
    });
  });

  group('qaScoreableAspects', () {
    test('lists only aspects the entry actually has', () {
      expect(qaScoreableAspects(const FactEntry(text: 'hi')), ['text']);
      expect(qaScoreableAspects(const FactEntry(audio: 'aud1')), ['audio']);
      expect(qaScoreableAspects(const FactEntry(text: ' hi ', audio: 'aud1')), [
        'text',
        'audio',
      ]);
      expect(qaScoreableAspects(const FactEntry(image: 'img1')), isEmpty);
    });
  });

  group('qaMergedQualityEntries', () {
    const entries = [
      FactEntry(text: 'a', audio: 'aud-a'),
      FactEntry(text: 'b'),
      FactEntry(image: 'img'),
    ];

    test('scores checked columns as human/10 on every scoreable aspect', () {
      final merged = qaMergedQualityEntries(
        entries: entries,
        checkedIndexes: {0},
      );

      expect(merged, {
        '0': {
          'text': {'score': 10, 'model': 'human'},
          'audio': {'score': 10, 'model': 'human'},
        },
      });
    });

    test('keeps prior AI scores on unchecked columns', () {
      final quality = FactQuality.fromJson({
        'entries': {
          '1': {
            'text': {'score': 2, 'model': 'claude'},
          },
        },
      });

      final merged = qaMergedQualityEntries(
        quality: quality,
        entries: entries,
        checkedIndexes: const {},
      );

      expect(merged, {
        '1': {
          'text': {'score': 2, 'model': 'claude'},
        },
      });
    });

    test('drops human scores from unchecked columns', () {
      final quality = FactQuality.fromJson({
        'entries': {
          '0': {
            'text': {'score': 10, 'model': 'human'},
            'audio': {'score': 5, 'model': 'elevenlabs'},
          },
        },
      });

      final merged = qaMergedQualityEntries(
        quality: quality,
        entries: entries,
        checkedIndexes: const {},
      );

      expect(merged, {
        '0': {
          'audio': {'score': 5, 'model': 'elevenlabs'},
        },
      });
    });

    test('human sign-off overrides a prior AI score on the same aspect', () {
      final quality = FactQuality.fromJson({
        'entries': {
          '1': {
            'text': {'score': 2, 'model': 'claude'},
          },
        },
      });

      final merged = qaMergedQualityEntries(
        quality: quality,
        entries: entries,
        checkedIndexes: {1},
      );

      expect(merged, {
        '1': {
          'text': {'score': 10, 'model': 'human'},
        },
      });
    });

    test('omits columns with nothing to score', () {
      final merged = qaMergedQualityEntries(
        entries: entries,
        checkedIndexes: {2},
      );

      expect(merged, isEmpty);
    });
  });
}
