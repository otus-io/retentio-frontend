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

    test('fromJson parses media version maps', () {
      final result = DeckUpdatesResult.fromJson({
        'source_version': 1,
        'latest_version': 2,
        'before_media_versions': {'aud1': 1},
        'after_media_versions': {'aud1': 2, 'aud2': 1},
      });

      expect(result.beforeMediaVersions, {'aud1': 1});
      expect(result.afterMediaVersions, {'aud1': 2, 'aud2': 1});
    });

    test('mediaPlayUrl appends published version for media ids', () {
      expect(
        DeckUpdatesResult.mediaPlayUrl('aud1', {'aud1': 3}),
        '/api/media/aud1?v=3',
      );
      expect(
        DeckUpdatesResult.mediaPlayUrl('/api/media/aud1?v=1', {}),
        '/api/media/aud1?v=1',
      );
      expect(DeckUpdatesResult.mediaPlayUrl('', {'aud1': 1}), isNull);
    });

    test('defaultDecisions prefers accept for all facts', () {
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
      expect(decisions['r1'], SyncFactDecisionAction.accept);
      expect(decisions['r2'], SyncFactDecisionAction.accept);
      expect(decisions['e1'], SyncFactDecisionAction.accept);
      expect(decisions['e2'], SyncFactDecisionAction.accept);
    });
    test('DeckUpdatesSummary fromJson parses id lists', () {
      final summary = DeckUpdatesSummary.fromJson({
        'source_version': 1,
        'latest_version': 3,
        'added_fact_ids': ['a1'],
        'removed_fact_ids': ['r1'],
        'edited_fact_ids': ['e1', 'e2'],
        'media_change_count': 12,
        'card_template_change_count': 1,
      });
      expect(summary.sourceVersion, 1);
      expect(summary.latestVersion, 3);
      expect(summary.addedFactIds, ['a1']);
      expect(summary.editedFactIds, ['e1', 'e2']);
      expect(summary.mediaChangeCount, 12);
      expect(summary.hasUpdates, isTrue);
    });
  });

  group('DeckUpdateFactDetail', () {
    test('fromJson maps kind, versions, flags, and facts', () {
      final detail = DeckUpdateFactDetail.fromJson({
        'fact_id': 'fact0001',
        'kind': 'edited',
        'source_version': 2,
        'latest_version': 5,
        'has_local_overlay': true,
        'local': false,
        'aligned': true,
        'default_action': 'accept',
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
        'before_media_versions': {'aud1': 1},
        'after_media_versions': {'aud1': 2, 'aud2': 0},
      });

      expect(detail.factId, 'fact0001');
      expect(detail.kind, DeckUpdateFactKind.edited);
      expect(detail.sourceVersion, 2);
      expect(detail.latestVersion, 5);
      expect(detail.hasLocalOverlay, isTrue);
      expect(detail.local, isFalse);
      expect(detail.aligned, isTrue);
      expect(detail.defaultAction, 'accept');
      expect(detail.before?.entries.first.text, 'Old');
      expect(detail.after?.entries.first.text, 'New');
      expect(detail.beforeMediaVersions, {'aud1': 1});
      expect(detail.afterMediaVersions, {'aud1': 2});
    });

    test('fromJson maps removed keep default and added fact', () {
      final removed = DeckUpdateFactDetail.fromJson({
        'fact_id': 'r1',
        'kind': 'removed',
        'default_action': 'keep',
        'local': true,
        'fact': {
          'id': 'r1',
          'entries': [
            {'text': 'Gone'},
          ],
        },
      });
      expect(removed.kind, DeckUpdateFactKind.removed);
      expect(removed.defaultAction, 'keep');
      expect(removed.local, isTrue);
      expect(removed.fact?.entries.first.text, 'Gone');

      final added = DeckUpdateFactDetail.fromJson({
        'fact_id': 'a1',
        'kind': 'added',
        'fact': {
          'id': 'a1',
          'entries': [
            {'text': 'New'},
          ],
        },
      });
      expect(added.kind, DeckUpdateFactKind.added);
      expect(added.fact?.entries.first.text, 'New');
    });

    test('fromJson maps removed with null fact and media defaults', () {
      final detail = DeckUpdateFactDetail.fromJson({
        'fact_id': 'r-null',
        'kind': 'removed',
        'fact': null,
        'before_media_versions': null,
        'after_media_versions': null,
      });
      expect(detail.kind, DeckUpdateFactKind.removed);
      expect(detail.fact, isNull);
      expect(detail.beforeMediaVersions, isEmpty);
    });

    test('fromJson defaults empty kind to edited and tolerates nulls', () {
      final detail = DeckUpdateFactDetail.fromJson({
        'kind': '',
        'before_media_versions': null,
        'after_media_versions': 'bad',
      });
      expect(detail.kind, DeckUpdateFactKind.edited);
      expect(detail.factId, '');
      expect(detail.sourceVersion, 0);
      expect(detail.latestVersion, 0);
      expect(detail.beforeMediaVersions, isEmpty);
      expect(detail.afterMediaVersions, isEmpty);
    });

    test('fromJson throws on unrecognized non-empty kind', () {
      expect(
        () => DeckUpdateFactDetail.fromJson({'kind': 'unknown'}),
        throwsArgumentError,
      );
    });
  });
}
