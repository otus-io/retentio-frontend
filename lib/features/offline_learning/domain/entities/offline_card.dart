/// Local scheduling row for one card (backend `deck.Card` shape plus `dirty`).
class OfflineCard {
  const OfflineCard({
    required this.deckId,
    required this.id,
    required this.factId,
    required this.template,
    required this.lastReview,
    required this.dueDate,
    this.hidden = false,
    this.createdAt = 0,
    this.dirty = false,
  });

  final String deckId;
  final String id;
  final String factId;

  /// `[[front entry indexes], [back entry indexes]]`.
  final List<List<int>> template;
  final int lastReview;
  final int dueDate;
  final bool hidden;
  final int createdAt;

  /// True while a local change has not been confirmed by the server.
  final bool dirty;

  OfflineCard copyWith({
    int? lastReview,
    int? dueDate,
    bool? hidden,
    bool? dirty,
  }) => OfflineCard(
    deckId: deckId,
    id: id,
    factId: factId,
    template: template,
    lastReview: lastReview ?? this.lastReview,
    dueDate: dueDate ?? this.dueDate,
    hidden: hidden ?? this.hidden,
    createdAt: createdAt,
    dirty: dirty ?? this.dirty,
  );

  factory OfflineCard.fromJson(Map<String, dynamic> json) => OfflineCard(
    deckId: '${json['deck_id'] ?? ''}',
    id: '${json['id'] ?? ''}',
    factId: '${json['fact_id'] ?? ''}',
    template: [
      for (final side in (json['template'] as List? ?? const []))
        [for (final i in (side as List? ?? const [])) (i as num).toInt()],
    ],
    lastReview: (json['last_review'] as num?)?.toInt() ?? 0,
    dueDate: (json['due_date'] as num?)?.toInt() ?? 0,
    hidden: json['hidden'] == true,
    createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
    dirty: json['dirty'] == true,
  );

  Map<String, dynamic> toJson() => {
    'deck_id': deckId,
    'id': id,
    'fact_id': factId,
    'template': template,
    'last_review': lastReview,
    'due_date': dueDate,
    'hidden': hidden,
    'created_at': createdAt,
    'dirty': dirty,
  };
}
