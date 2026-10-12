/// Local deck metadata. A deck is study-ready only when [downloadedAt] > 0.
class OfflineDeck {
  const OfflineDeck({
    required this.id,
    required this.name,
    required this.fields,
    this.rate = 0,
    this.sourceDeckId = '',
    this.sourceVersion = 0,
    this.totalReviews = 0,
    this.totalReviewsToday = 0,
    this.downloadedAt = 0,
    this.lastSyncedAt = 0,
  });

  final String id;
  final String name;
  final List<String> fields;
  final int rate;
  final String sourceDeckId;
  final int sourceVersion;

  /// Server counters, refreshed from `GET /api/decks/{id}` after each flush.
  final int totalReviews;
  final int totalReviewsToday;
  final int downloadedAt;
  final int lastSyncedAt;

  bool get isReady => downloadedAt > 0;

  OfflineDeck copyWith({
    int? totalReviews,
    int? totalReviewsToday,
    int? downloadedAt,
    int? lastSyncedAt,
  }) => OfflineDeck(
    id: id,
    name: name,
    fields: fields,
    rate: rate,
    sourceDeckId: sourceDeckId,
    sourceVersion: sourceVersion,
    totalReviews: totalReviews ?? this.totalReviews,
    totalReviewsToday: totalReviewsToday ?? this.totalReviewsToday,
    downloadedAt: downloadedAt ?? this.downloadedAt,
    lastSyncedAt: lastSyncedAt ?? this.lastSyncedAt,
  );

  factory OfflineDeck.fromJson(Map<String, dynamic> json) => OfflineDeck(
    id: '${json['id'] ?? ''}',
    name: '${json['name'] ?? ''}',
    fields: [for (final f in (json['fields'] as List? ?? const [])) '$f'],
    rate: (json['rate'] as num?)?.toInt() ?? 0,
    sourceDeckId: '${json['source_deck_id'] ?? ''}',
    sourceVersion: (json['source_version'] as num?)?.toInt() ?? 0,
    totalReviews: (json['total_reviews'] as num?)?.toInt() ?? 0,
    totalReviewsToday: (json['total_reviews_today'] as num?)?.toInt() ?? 0,
    downloadedAt: (json['downloaded_at'] as num?)?.toInt() ?? 0,
    lastSyncedAt: (json['last_synced_at'] as num?)?.toInt() ?? 0,
  );

  Map<String, dynamic> toJson() => {
    'id': id,
    'name': name,
    'fields': fields,
    'rate': rate,
    'source_deck_id': sourceDeckId,
    'source_version': sourceVersion,
    'total_reviews': totalReviews,
    'total_reviews_today': totalReviewsToday,
    'downloaded_at': downloadedAt,
    'last_synced_at': lastSyncedAt,
  };
}
