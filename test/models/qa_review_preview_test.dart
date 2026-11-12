import 'package:flutter_test/flutter_test.dart';
import 'package:retentio/models/deck_contribution.dart';
import 'package:retentio/models/qa_review_preview.dart';

void main() {
  group('QAReviewSummary', () {
    test('parses submit and accept counts on a qa_review row', () {
      final c = DeckContribution.fromJson({
        'id': 'cont9',
        'type': 'qa_review',
        'status': 'accepted',
        'qa_review': {
          'facts': 2,
          'aspects': '4',
          'signed_aspects': 3.0,
          'skipped_aspects': 1,
        },
      });

      expect(c.isQAReview, isTrue);
      expect(c.qaReview!.facts, 2);
      expect(c.qaReview!.aspects, 4);
      expect(c.qaReview!.signedAspects, 3);
      expect(c.qaReview!.skippedAspects, 1);
    });

    test('is absent on other types and tolerates loose values', () {
      final edit = DeckContribution.fromJson({'type': 'fact_edit'});
      expect(edit.isQAReview, isFalse);
      expect(edit.qaReview, isNull);

      final loose = QAReviewSummary.tryParse({'facts': 'x'})!;
      expect(loose.facts, 0);
      expect(loose.aspects, 0);
      expect(loose.signedAspects, isNull);
    });
  });

  group('QAReviewPreview', () {
    test('parses summary counts and per-fact statuses', () {
      final p = QAReviewPreview.fromJson({
        'summary': {'ready': 2, 'changed': 1, 'verified': 0, 'removed': 1},
        'facts': [
          {
            'fact_id': 'fa',
            'preview': 'Apple',
            'aspects': [
              {'entry': 0, 'aspect': 'text', 'status': 'ready'},
              {'entry': 1.0, 'aspect': 'audio', 'status': 'changed'},
            ],
          },
          {
            'fact_id': 'fb',
            'aspects': [
              {'status': 'removed'},
              {'entry': 'x', 'status': 'verified'},
              {'status': 'unknown'},
            ],
          },
          'not a map',
        ],
      });

      expect(p.count(QAReviewItemStatus.ready), 2);
      expect(p.count(QAReviewItemStatus.removed), 1);
      expect(p.total, 4);
      expect(p.facts, hasLength(2));
      expect(p.facts.first.preview, 'Apple');
      expect(p.facts.first.aspects[1].entry, 1);
      expect(p.facts.first.aspects[1].aspect, 'audio');
      expect(p.facts.first.aspects[1].status, QAReviewItemStatus.changed);
      final fb = p.facts[1];
      expect(fb.preview, isEmpty);
      expect(fb.aspects.map((a) => a.status), [
        QAReviewItemStatus.removed,
        QAReviewItemStatus.verified,
        QAReviewItemStatus.changed,
      ]);
      expect(fb.aspects.first.aspect, 'text');
      expect(fb.aspects[1].entry, 0);
    });

    test('defaults to empty without summary or facts', () {
      final p = QAReviewPreview.fromJson({
        'summary': {'ready': 'x'},
      });
      expect(p.count(QAReviewItemStatus.ready), 0);
      expect(p.count(QAReviewItemStatus.changed), 0);
      expect(p.facts, isEmpty);
      expect(QAReviewPreview.fromJson(const {}).total, 0);
    });
  });
}
