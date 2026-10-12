import 'package:retentio/models/fact.dart';

/// Local fact row: entries keep raw media ids; tags are stored as ids only.
class OfflineFact {
  const OfflineFact({
    required this.deckId,
    required this.id,
    required this.entries,
    this.tagIds = const [],
  });

  final String deckId;
  final String id;
  final List<FactEntry> entries;
  final List<String> tagIds;

  factory OfflineFact.fromJson(Map<String, dynamic> json) => OfflineFact(
    deckId: '${json['deck_id'] ?? ''}',
    id: '${json['id'] ?? ''}',
    entries: [
      for (final e in (json['entries'] as List? ?? const []))
        if (e is Map) FactEntry.fromJson(Map<String, dynamic>.from(e)),
    ],
    tagIds: [for (final t in (json['tag_ids'] as List? ?? const [])) '$t'],
  );

  Map<String, dynamic> toJson() => {
    'deck_id': deckId,
    'id': id,
    'entries': [for (final e in entries) e.toJson()],
    'tag_ids': tagIds,
  };
}
