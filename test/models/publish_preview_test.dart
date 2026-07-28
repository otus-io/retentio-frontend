import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/publish_preview.dart';

void main() {
  group('PublishPreview.fromJson', () {
    test('parses counts and builds summary', () {
      final preview = PublishPreview.fromJson({
        'published_version': 3,
        'has_unpublished_changes': true,
        'facts': {'added': 1, 'edited': 2, 'removed': 0},
        'media': {'added': 0, 'updated': 1, 'deleted': 0},
        'tags': {
          'deck': {'added': 0, 'removed': 0},
          'facts': {'added': 1, 'removed': 0, 'facts_changed': 1},
        },
        'card_templates_changed': 0,
        'meta_changed': false,
      });

      expect(preview.publishedVersion, 3);
      expect(preview.hasUnpublishedChanges, isTrue);
      expect(preview.facts.edited, 2);
      expect(preview.media.updated, 1);
      expect(preview.tags.facts.factsChanged, 1);
      expect(preview.summaryLine(), contains('2 facts edited'));
      expect(preview.summaryLine(), contains('1 media updated'));
      expect(preview.summaryLine(), contains("1 facts' tags changed"));
      expect(preview.summaryLine(), contains('not yet published'));
    });

    test('parses detail rows', () {
      final preview = PublishPreview.fromJson({
        'published_version': 2,
        'has_unpublished_changes': true,
        'facts': {'added': 1, 'edited': 1, 'removed': 1},
        'media': {'added': 1, 'updated': 0, 'deleted': 1},
        'tags': {
          'deck': {'added': 1, 'removed': 0},
          'facts': {'added': 0, 'removed': 0, 'facts_changed': 0},
        },
        'card_templates_changed': 2,
        'meta_changed': true,
        'added_facts': [
          {'fact_id': 'a1', 'preview': 'new'},
        ],
        'edited_facts': [
          {'fact_id': 'e1', 'preview_before': 'old', 'preview_after': 'new'},
        ],
        'removed_facts': [
          {'fact_id': 'r1', 'preview': 'gone'},
        ],
        'media_changes': [
          {'media_id': 'm1', 'change': 'added'},
          {'media_id': 'm2', 'change': 'deleted'},
        ],
      });

      expect(preview.addedFacts.single.factId, 'a1');
      expect(preview.editedFacts.single.previewBefore, 'old');
      expect(preview.removedFacts.single.preview, 'gone');
      expect(preview.mediaChanges, hasLength(2));
      expect(preview.cardTemplatesChanged, 2);
      expect(preview.metaChanged, isTrue);
      expect(preview.tags.deck.added, 1);
      expect(preview.summaryLine(), contains('deck tags changed'));
      expect(preview.summaryLine(), contains('2 templates changed'));
      expect(preview.summaryLine(), contains('deck info changed'));
    });

    test('tolerates missing nested maps', () {
      final preview = PublishPreview.fromJson({
        'published_version': 0,
        'has_unpublished_changes': false,
      });
      expect(preview.facts.added, 0);
      expect(preview.media.deleted, 0);
      expect(preview.tags.facts.factsChanged, 0);
      expect(preview.summaryLine(), 'No unpublished changes');
    });

    test('dirty with empty counts still reports unpublished', () {
      final preview = PublishPreview.fromJson({
        'published_version': 1,
        'has_unpublished_changes': true,
        'facts': {'added': 0, 'edited': 0, 'removed': 0},
        'media': {'added': 0, 'updated': 0, 'deleted': 0},
      });
      expect(preview.summaryLine(), 'Unpublished changes');
    });
  });
}
