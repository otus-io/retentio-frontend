import 'package:retentio/models/fact.dart';

/// Local fact row: entries keep raw media ids; tags are stored as ids only.
class OfflineFact {
  const OfflineFact({
    required this.deckId,
    required this.id,
    required this.entries,
    this.tagIds = const [],
    this.mediaVersions,
  });

  final String deckId;
  final String id;
  final List<FactEntry> entries;
  final List<String> tagIds;

  /// Published versions pinned by an imported deck (media id → `v`); null
  /// when not resolved. Unpinned media are the importer's own overlays.
  final Map<String, int>? mediaVersions;

  /// Non-empty audio, image, video and json ids.
  Set<String> get mediaIds => {
    for (final e in entries) ...[e.audio, e.image, e.video, e.json],
  }..remove('');

  /// Media cache key, also the path after `/api/media/`: pinned versions get
  /// their own key so a new snapshot never reuses an older file.
  String mediaKey(String mediaId) {
    final version = mediaVersions?[mediaId];
    return version == null ? mediaId : '$mediaId?v=$version';
  }

  OfflineFact withMediaVersions(Map<String, int>? versions) => OfflineFact(
    deckId: deckId,
    id: id,
    entries: entries,
    tagIds: tagIds,
    mediaVersions: versions,
  );

  factory OfflineFact.fromJson(Map<String, dynamic> json) => OfflineFact(
    deckId: '${json['deck_id'] ?? ''}',
    id: '${json['id'] ?? ''}',
    entries: [
      for (final e in (json['entries'] as List? ?? const []))
        if (e is Map) FactEntry.fromJson(Map<String, dynamic>.from(e)),
    ],
    tagIds: [for (final t in (json['tag_ids'] as List? ?? const [])) '$t'],
    mediaVersions: switch (json['media_versions']) {
      final Map raw => {
        for (final MapEntry(:key, :value) in raw.entries)
          if (value case final int v) '$key': v,
      },
      _ => null,
    },
  );

  Map<String, dynamic> toJson() => {
    'deck_id': deckId,
    'id': id,
    'entries': [for (final e in entries) e.toJson()],
    'tag_ids': tagIds,
    if (mediaVersions != null) 'media_versions': mediaVersions,
  };
}
