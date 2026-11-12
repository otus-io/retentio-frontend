/// Live status of one importer sign-off in a `qa_review` request.
enum QAReviewItemStatus {
  /// Content still matches and the author has not signed it yet.
  ready,

  /// The author's content differs from what the importer verified.
  changed,

  /// The author already signed this field off.
  verified,

  /// The fact is no longer on the author's deck.
  removed;

  static QAReviewItemStatus parse(String raw) => switch (raw) {
    'ready' => ready,
    'verified' => verified,
    'removed' => removed,
    _ => changed,
  };
}

class QAReviewPreviewAspect {
  const QAReviewPreviewAspect({
    required this.entry,
    required this.aspect,
    required this.status,
  });

  final int entry;

  /// `text` or `audio`.
  final String aspect;
  final QAReviewItemStatus status;
}

class QAReviewPreviewFact {
  const QAReviewPreviewFact({
    required this.factId,
    required this.preview,
    required this.aspects,
  });

  final String factId;

  /// First non-empty text of the author's fact; empty once removed.
  final String preview;
  final List<QAReviewPreviewAspect> aspects;
}

/// Author view of a `qa_review` request (`GET …/contributions/{id}/qa-review`).
class QAReviewPreview {
  const QAReviewPreview({required this.counts, required this.facts});

  final Map<QAReviewItemStatus, int> counts;
  final List<QAReviewPreviewFact> facts;

  int count(QAReviewItemStatus status) => counts[status] ?? 0;

  int get total => counts.values.fold(0, (a, b) => a + b);

  factory QAReviewPreview.fromJson(Map<String, dynamic> json) {
    final counts = <QAReviewItemStatus, int>{};
    final summary = json['summary'];
    if (summary is Map) {
      for (final status in QAReviewItemStatus.values) {
        final n = summary[status.name];
        counts[status] = n is num ? n.toInt() : 0;
      }
    }
    final facts = <QAReviewPreviewFact>[];
    final rawFacts = json['facts'];
    if (rawFacts is List) {
      for (final f in rawFacts.whereType<Map>()) {
        facts.add(_factFromJson(f));
      }
    }
    return QAReviewPreview(counts: counts, facts: facts);
  }

  static QAReviewPreviewFact _factFromJson(Map<dynamic, dynamic> f) {
    final aspects = <QAReviewPreviewAspect>[];
    final raw = f['aspects'];
    if (raw is List) {
      for (final a in raw.whereType<Map>()) {
        final entry = a['entry'];
        aspects.add(
          QAReviewPreviewAspect(
            entry: entry is num ? entry.toInt() : 0,
            aspect: a['aspect']?.toString() ?? 'text',
            status: QAReviewItemStatus.parse(a['status']?.toString() ?? ''),
          ),
        );
      }
    }
    return QAReviewPreviewFact(
      factId: f['fact_id']?.toString() ?? '',
      preview: f['preview']?.toString() ?? '',
      aspects: aspects,
    );
  }
}
