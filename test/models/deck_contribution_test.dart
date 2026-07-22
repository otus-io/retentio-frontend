import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck_contribution.dart';

void main() {
  group('DeckContribution', () {
    test('fromJson parses before/after entry diff for fact_edit', () {
      final c = DeckContribution.fromJson({
        'id': 'cont0001',
        'type': 'fact_edit',
        'status': 'open',
        'fact_id': 'fact0001',
        'reporter': 'bob',
        'source_version': 3,
        'message': 'fix audio',
        'reported_fact': {
          'id': 'fact0001',
          'entries': [
            {'text': 'Apple'},
            {'text': 'リンゴ'},
          ],
        },
        'proposed_entries': [
          {'text': 'Apple'},
          {'text': 'りんご'},
        ],
      });

      expect(c.id, 'cont0001');
      expect(c.type, 'fact_edit');
      expect(c.hasEntryDiff, isTrue);
      expect(c.reportedFact?.entries[1].text, 'リンゴ');
      expect(c.proposedEntries[1].text, 'りんご');
      expect(c.sourceVersion, 3);
    });

    test('fromJson parses media attachment preview for proposed audio', () {
      final c = DeckContribution.fromJson({
        'id': 'cont0001',
        'type': 'fact_edit',
        'status': 'open',
        'source_deck_id': 'srcdeck12345',
        'reported_fact': {
          'id': 'fact0001',
          'entries': [
            {'text': 'Apple', 'audio': 'sourceaud1'},
          ],
        },
        'proposed_entries': [
          {'text': 'Apple', 'audio': 'impaud0001'},
        ],
        'media_attachments': [
          {
            'attachment_id': 'attach01',
            'source_media_id': 'impaud0001',
            'mime': 'audio/mpeg',
            'filename': 'apple.mp3',
            'preview_path':
                '/api/decks/srcdeck12345/contributions/cont0001/media/attach01',
            'references': [
              {'entry_index': 0, 'field': 'audio'},
            ],
          },
        ],
      });

      expect(c.beforeAudioUrl(0), '/api/media/sourceaud1');
      expect(
        c.afterAudioUrl(0),
        '/api/decks/srcdeck12345/contributions/cont0001/media/attach01',
      );
    });

    test('afterAudioUrl falls back to contribution media path', () {
      final c = DeckContribution.fromJson({
        'id': 'cont0001',
        'type': 'fact_edit',
        'status': 'open',
        'source_deck_id': 'srcdeck12345',
        'proposed_entries': [
          {'text': 'Apple', 'audio': 'impaud0001'},
        ],
      });

      expect(
        c.afterAudioUrl(0),
        '/api/decks/srcdeck12345/contributions/cont0001/media/impaud0001',
      );
    });

    test('afterAudioUrl single-attachment fallback respects entry index', () {
      final c = DeckContribution.fromJson({
        'id': 'cont0001',
        'type': 'fact_edit',
        'status': 'open',
        'source_deck_id': 'srcdeck12345',
        'proposed_entries': [
          {'text': 'Apple', 'audio': 'impaud0001'},
          {'text': 'Orange', 'audio': 'impaud0002'},
        ],
        'media_attachments': [
          {
            'attachment_id': 'attach01',
            'source_media_id': 'impaud0001',
            'mime': 'audio/mpeg',
            'filename': 'apple.mp3',
            'preview_path':
                '/api/decks/srcdeck12345/contributions/cont0001/media/attach01',
            'references': [
              {'entry_index': 0, 'field': 'audio'},
            ],
          },
        ],
      });

      expect(
        c.afterAudioUrl(0),
        '/api/decks/srcdeck12345/contributions/cont0001/media/attach01',
      );
      // Sole attachment maps to entry 0 — must not leak to entry 1.
      expect(
        c.afterAudioUrl(1),
        '/api/decks/srcdeck12345/contributions/cont0001/media/impaud0002',
      );
    });
  });
}
