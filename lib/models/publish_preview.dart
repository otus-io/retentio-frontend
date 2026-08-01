/// Author working-copy vs last publish — `GET /api/decks/{id}/publish-preview`.
class PublishPreview {
  const PublishPreview({
    required this.publishedVersion,
    required this.hasUnpublishedChanges,
    this.facts = const PublishPreviewFactCounts(),
    this.media = const PublishPreviewMediaCounts(),
    this.tags = const PublishPreviewTags(),
    this.cardTemplatesChanged = 0,
    this.metaChanged = false,
    this.addedFacts = const [],
    this.editedFacts = const [],
    this.removedFacts = const [],
    this.mediaChanges = const [],
  });

  final int publishedVersion;
  final bool hasUnpublishedChanges;
  final PublishPreviewFactCounts facts;
  final PublishPreviewMediaCounts media;
  final PublishPreviewTags tags;
  final int cardTemplatesChanged;
  final bool metaChanged;
  final List<PublishPreviewFactRef> addedFacts;
  final List<PublishPreviewFactRef> editedFacts;
  final List<PublishPreviewFactRef> removedFacts;
  final List<PublishPreviewMediaChange> mediaChanges;

  factory PublishPreview.fromJson(Map<String, dynamic> data) {
    int n(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      return 0;
    }

    List<PublishPreviewFactRef> factRefs(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => PublishPreviewFactRef.fromJson(Map<String, dynamic>.from(e)),
          )
          .toList();
    }

    List<PublishPreviewMediaChange> mediaRows(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => PublishPreviewMediaChange.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    final factsRaw = data['facts'];
    final mediaRaw = data['media'];
    final tagsRaw = data['tags'];

    return PublishPreview(
      publishedVersion: n(data['published_version']),
      hasUnpublishedChanges: data['has_unpublished_changes'] == true,
      facts: factsRaw is Map
          ? PublishPreviewFactCounts.fromJson(
              Map<String, dynamic>.from(factsRaw),
            )
          : const PublishPreviewFactCounts(),
      media: mediaRaw is Map
          ? PublishPreviewMediaCounts.fromJson(
              Map<String, dynamic>.from(mediaRaw),
            )
          : const PublishPreviewMediaCounts(),
      tags: tagsRaw is Map
          ? PublishPreviewTags.fromJson(Map<String, dynamic>.from(tagsRaw))
          : const PublishPreviewTags(),
      cardTemplatesChanged: n(data['card_templates_changed']),
      metaChanged: data['meta_changed'] == true,
      addedFacts: factRefs(data['added_facts']),
      editedFacts: factRefs(data['edited_facts']),
      removedFacts: factRefs(data['removed_facts']),
      mediaChanges: mediaRows(data['media_changes']),
    );
  }

  /// One-line summary for the publish sheet (non-empty parts only).
  String summaryLine() {
    final parts = <String>[];
    if (facts.edited > 0) parts.add('${facts.edited} facts edited');
    if (facts.added > 0) parts.add('${facts.added} added');
    if (facts.removed > 0) parts.add('${facts.removed} removed');
    if (media.added > 0) parts.add('${media.added} media added');
    if (media.updated > 0) parts.add('${media.updated} media updated');
    if (media.deleted > 0) parts.add('${media.deleted} media deleted');
    if (tags.facts.factsChanged > 0) {
      parts.add("${tags.facts.factsChanged} facts' tags changed");
    } else if (tags.deck.added + tags.deck.removed > 0) {
      parts.add('deck tags changed');
    }
    if (cardTemplatesChanged > 0) {
      parts.add('$cardTemplatesChanged templates changed');
    }
    if (metaChanged) parts.add('deck info changed');
    if (parts.isEmpty) {
      return hasUnpublishedChanges
          ? 'Unpublished changes'
          : 'No unpublished changes';
    }
    return '${parts.join(' · ')} — not yet published';
  }
}

class PublishPreviewFactCounts {
  const PublishPreviewFactCounts({
    this.added = 0,
    this.edited = 0,
    this.removed = 0,
  });

  final int added;
  final int edited;
  final int removed;

  factory PublishPreviewFactCounts.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => v is num ? v.toInt() : 0;
    return PublishPreviewFactCounts(
      added: n(json['added']),
      edited: n(json['edited']),
      removed: n(json['removed']),
    );
  }
}

class PublishPreviewMediaCounts {
  const PublishPreviewMediaCounts({
    this.added = 0,
    this.updated = 0,
    this.deleted = 0,
  });

  final int added;
  final int updated;
  final int deleted;

  factory PublishPreviewMediaCounts.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => v is num ? v.toInt() : 0;
    return PublishPreviewMediaCounts(
      added: n(json['added']),
      updated: n(json['updated']),
      deleted: n(json['deleted']),
    );
  }
}

class PublishPreviewTags {
  const PublishPreviewTags({
    this.deck = const PublishPreviewDeckTagCounts(),
    this.facts = const PublishPreviewFactTagCounts(),
  });

  final PublishPreviewDeckTagCounts deck;
  final PublishPreviewFactTagCounts facts;

  factory PublishPreviewTags.fromJson(Map<String, dynamic> json) {
    final deckRaw = json['deck'];
    final factsRaw = json['facts'];
    return PublishPreviewTags(
      deck: deckRaw is Map
          ? PublishPreviewDeckTagCounts.fromJson(
              Map<String, dynamic>.from(deckRaw),
            )
          : const PublishPreviewDeckTagCounts(),
      facts: factsRaw is Map
          ? PublishPreviewFactTagCounts.fromJson(
              Map<String, dynamic>.from(factsRaw),
            )
          : const PublishPreviewFactTagCounts(),
    );
  }
}

class PublishPreviewDeckTagCounts {
  const PublishPreviewDeckTagCounts({this.added = 0, this.removed = 0});

  final int added;
  final int removed;

  factory PublishPreviewDeckTagCounts.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => v is num ? v.toInt() : 0;
    return PublishPreviewDeckTagCounts(
      added: n(json['added']),
      removed: n(json['removed']),
    );
  }
}

class PublishPreviewFactTagCounts {
  const PublishPreviewFactTagCounts({
    this.added = 0,
    this.removed = 0,
    this.factsChanged = 0,
  });

  final int added;
  final int removed;
  final int factsChanged;

  factory PublishPreviewFactTagCounts.fromJson(Map<String, dynamic> json) {
    int n(dynamic v) => v is num ? v.toInt() : 0;
    return PublishPreviewFactTagCounts(
      added: n(json['added']),
      removed: n(json['removed']),
      factsChanged: n(json['facts_changed']),
    );
  }
}

class PublishPreviewFactRef {
  const PublishPreviewFactRef({
    required this.factId,
    this.preview = '',
    this.previewBefore = '',
    this.previewAfter = '',
  });

  final String factId;
  final String preview;
  final String previewBefore;
  final String previewAfter;

  factory PublishPreviewFactRef.fromJson(Map<String, dynamic> json) {
    return PublishPreviewFactRef(
      factId: json['fact_id']?.toString() ?? '',
      preview: json['preview']?.toString() ?? '',
      previewBefore: json['preview_before']?.toString() ?? '',
      previewAfter: json['preview_after']?.toString() ?? '',
    );
  }
}

class PublishPreviewMediaChange {
  const PublishPreviewMediaChange({
    required this.mediaId,
    required this.change,
  });

  final String mediaId;

  /// `added` | `updated` | `deleted`
  final String change;

  factory PublishPreviewMediaChange.fromJson(Map<String, dynamic> json) {
    return PublishPreviewMediaChange(
      mediaId: json['media_id']?.toString() ?? '',
      change: json['change']?.toString() ?? '',
    );
  }
}
