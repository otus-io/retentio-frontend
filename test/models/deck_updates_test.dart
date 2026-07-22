import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck_updates.dart';

void main() {
  group('DeckUpdatesResult', () {
    test('fromJson parses fact arrays not ints', () {
      final result = DeckUpdatesResult.fromJson({
        'source_version': 3,
        'latest_version': 4,
        'added_facts': [
          {
            'fact_id': 'local001',
            'fact': {
              'id': 'local001',
              'entries': [
                {'text': 'Orange'},
              ],
            },
            'has_local_overlay': true,
            'aligned': true,
          },
        ],
        'removed_facts': [
          {
            'fact_id': 'fact0002',
            'has_local_overlay': true,
            'local': true,
            'default_action': 'keep',
            'fact': {
              'id': 'fact0002',
              'entries': [
                {'text': 'Banana'},
              ],
            },
          },
        ],
        'edited_facts': [
          {
            'fact_id': 'fact0001',
            'aligned': false,
            'has_local_overlay': true,
            'before': {
              'id': 'fact0001',
              'entries': [
                {'text': 'Old'},
              ],
            },
            'after': {
              'id': 'fact0001',
              'entries': [
                {'text': 'New'},
              ],
            },
          },
        ],
        'media_changes': [
          {'media_id': 'media12345'},
        ],
        'card_template_changes': [
          {'fact_id': 'fact0001'},
        ],
      });

      expect(result.sourceVersion, 3);
      expect(result.latestVersion, 4);
      expect(result.addedFacts, hasLength(1));
      expect(result.removedFacts, hasLength(1));
      expect(result.editedFacts, hasLength(1));
      expect(result.mediaChanges, hasLength(1));
      expect(result.cardTemplateChanges, hasLength(1));
      expect(result.hasUpdates, isTrue);
      expect(result.addedFacts.first.hasLocalOverlay, isTrue);
      expect(result.addedFacts.first.fact?.entries.first.text, 'Orange');
    });

    test('fromJson tolerates null versions and update arrays', () {
      final result = DeckUpdatesResult.fromJson({
        'source_version': null,
        'latest_version': null,
        'added_facts': null,
        'removed_facts': null,
        'edited_facts': null,
        'media_changes': null,
        'card_template_changes': null,
      });

      expect(result.sourceVersion, 0);
      expect(result.latestVersion, 0);
      expect(result.addedFacts, isEmpty);
      expect(result.removedFacts, isEmpty);
      expect(result.editedFacts, isEmpty);
      expect(result.mediaChanges, isEmpty);
      expect(result.cardTemplateChanges, isEmpty);
    });

    test('defaultDecisions matches overlay defaults', () {
      final result = DeckUpdatesResult.fromJson({
        'source_version': 1,
        'latest_version': 2,
        'added_facts': [],
        'removed_facts': [
          {
            'fact_id': 'r1',
            'has_local_overlay': true,
            'default_action': 'keep',
          },
          {'fact_id': 'r2'},
        ],
        'edited_facts': [
          {'fact_id': 'e1', 'aligned': true},
          {'fact_id': 'e2', 'aligned': false, 'has_local_overlay': true},
        ],
        'media_changes': [],
      });

      final decisions = result.defaultDecisions();
      expect(decisions['r1'], SyncFactDecisionAction.keep);
      expect(decisions['r2'], SyncFactDecisionAction.accept);
      expect(decisions['e1'], SyncFactDecisionAction.accept);
      expect(decisions['e2'], SyncFactDecisionAction.keep);
    });
  });
}
