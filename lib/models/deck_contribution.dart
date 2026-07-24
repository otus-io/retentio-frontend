import 'package:retentio/models/fact.dart';

/// Frozen proposed media on a contribution (author can download via [previewPath]).
class ContributionMediaAttachment {
  const ContributionMediaAttachment({
    required this.attachmentId,
    this.sourceMediaId = '',
    this.previewPath = '',
    this.mime = '',
    this.filename = '',
    this.entryIndexes = const [],
    this.fields = const [],
  });

  final String attachmentId;
  final String sourceMediaId;
  final String previewPath;
  final String mime;
  final String filename;
  final List<int> entryIndexes;
  final List<String> fields;

  bool get isAudio =>
      mime.startsWith('audio/') ||
      fields.contains('audio') ||
      filename.toLowerCase().endsWith('.mp3') ||
      filename.toLowerCase().endsWith('.m4a') ||
      filename.toLowerCase().endsWith('.wav') ||
      filename.toLowerCase().endsWith('.aac');

  factory ContributionMediaAttachment.fromJson(Map<String, dynamic> json) {
    final refs = json['references'];
    final indexes = <int>[];
    final fields = <String>[];
    if (refs is List) {
      for (final r in refs) {
        if (r is! Map) continue;
        final idx = r['entry_index'];
        if (idx is int) {
          indexes.add(idx);
        } else if (idx is num) {
          indexes.add(idx.toInt());
        } else if (idx is String) {
          final parsed = int.tryParse(idx);
          if (parsed != null) indexes.add(parsed);
        }
        final field = r['field']?.toString();
        if (field != null && field.isNotEmpty) fields.add(field);
      }
    }
    return ContributionMediaAttachment(
      attachmentId: json['attachment_id']?.toString() ?? '',
      sourceMediaId: json['source_media_id']?.toString() ?? '',
      previewPath: json['preview_path']?.toString() ?? '',
      mime: json['mime']?.toString() ?? '',
      filename: json['filename']?.toString() ?? '',
      entryIndexes: indexes,
      fields: fields,
    );
  }
}

/// Author-inbox / submit contribution row from the sharing API.
class DeckContribution {
  const DeckContribution({
    required this.id,
    required this.type,
    required this.status,
    this.factId = '',
    this.message = '',
    this.reporter = '',
    this.sourceDeckId = '',
    this.sourceVersion = 0,
    this.addTags = const [],
    this.removeTags = const [],
    this.reportedTags = const [],
    this.reportedFields = const [],
    this.proposedFields = const [],
    this.reportedFact,
    this.proposedEntries = const [],
    this.mediaAttachments = const [],
    this.workingCopyUpdated = false,
  });

  final String id;
  final String type;
  final String status;
  final String factId;
  final String message;
  final String reporter;
  final String sourceDeckId;
  final int sourceVersion;
  final List<String> addTags;
  final List<String> removeTags;
  final List<String> reportedTags;
  final List<String> reportedFields;
  final List<String> proposedFields;

  /// Snapshot / author baseline when the contribution was submitted ("before").
  final Fact? reportedFact;

  /// Importer proposal entries ("after") for fact_edit / fact_add.
  final List<FactEntry> proposedEntries;

  final List<ContributionMediaAttachment> mediaAttachments;

  final bool workingCopyUpdated;

  bool get hasEntryDiff => reportedFact != null || proposedEntries.isNotEmpty;

  bool get hasTagDiff => addTags.isNotEmpty || removeTags.isNotEmpty;

  bool get hasFieldRename =>
      proposedFields.isNotEmpty || reportedFields.isNotEmpty;

  /// Author-owned media download path for a raw id or absolute/relative URL.
  static String ownedMediaUrl(String idOrUrl) {
    final v = idOrUrl.trim();
    if (v.isEmpty) return '';
    if (v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('/')) {
      return v;
    }
    return '/api/media/$v';
  }

  /// Playable URL for baseline ("before") audio on [entryIndex].
  String? beforeAudioUrl(int entryIndex) {
    final entries = reportedFact?.entries ?? const <FactEntry>[];
    if (entryIndex < 0 || entryIndex >= entries.length) return null;
    final id = entries[entryIndex].audio.trim();
    if (id.isEmpty) return null;
    return ownedMediaUrl(id);
  }

  /// Playable URL for proposed ("after") audio on [entryIndex].
  /// Prefers frozen contribution attachment preview; otherwise the
  /// contribution-scoped preview path (source owner can hear importer media).
  String? afterAudioUrl(int entryIndex) {
    String? proposedMediaId;
    if (entryIndex >= 0 && entryIndex < proposedEntries.length) {
      proposedMediaId = proposedEntries[entryIndex].audio.trim();
      if (proposedMediaId.isNotEmpty) {
        for (final a in mediaAttachments) {
          if (a.sourceMediaId == proposedMediaId && a.previewPath.isNotEmpty) {
            return a.previewPath;
          }
        }
      }
    }

    for (final a in mediaAttachments) {
      final isAudioField =
          a.fields.contains('audio') || (a.fields.isEmpty && a.isAudio);
      if (!isAudioField) continue;
      if (a.entryIndexes.contains(entryIndex) && a.previewPath.isNotEmpty) {
        return a.previewPath;
      }
    }

    final audioAttachments = mediaAttachments
        .where((a) => a.isAudio && a.previewPath.isNotEmpty)
        .toList();
    // Single-attachment heuristic only when it is not mapped to a different entry.
    if (audioAttachments.length == 1) {
      final only = audioAttachments.first;
      if (only.entryIndexes.isEmpty || only.entryIndexes.contains(entryIndex)) {
        return only.previewPath;
      }
    }

    final mediaId = proposedMediaId ?? '';
    if (mediaId.isEmpty) return null;
    final deckId = sourceDeckId.trim();
    if (deckId.isNotEmpty && id.isNotEmpty) {
      return '/api/decks/$deckId/contributions/$id/media/$mediaId';
    }
    return ownedMediaUrl(mediaId);
  }

  factory DeckContribution.fromJson(Map<String, dynamic> json) {
    List<String> stringList(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => e.toString()).toList();
    }

    Fact? parseReportedFact(dynamic raw) {
      if (raw is! Map) return null;
      return Fact.fromJson(Map<String, dynamic>.from(raw));
    }

    List<FactEntry> parseEntries(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map((e) => FactEntry.fromJson(Map<String, dynamic>.from(e)))
          .toList();
    }

    List<ContributionMediaAttachment> parseAttachments(dynamic raw) {
      if (raw is! List) return const [];
      return raw
          .whereType<Map>()
          .map(
            (e) => ContributionMediaAttachment.fromJson(
              Map<String, dynamic>.from(e),
            ),
          )
          .toList();
    }

    int? toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return DeckContribution(
      id: (json['contribution_id'] ?? json['id'])?.toString() ?? '',
      type: json['type']?.toString() ?? '',
      status: json['status']?.toString() ?? '',
      factId: json['fact_id']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      reporter: json['reporter']?.toString() ?? '',
      sourceDeckId: json['source_deck_id']?.toString() ?? '',
      sourceVersion: toInt(json['source_version']) ?? 0,
      addTags: stringList(json['add_tags']),
      removeTags: stringList(json['remove_tags']),
      reportedTags: stringList(json['reported_tags']),
      reportedFields: stringList(json['reported_fields']),
      proposedFields: stringList(json['proposed_fields']),
      reportedFact: parseReportedFact(json['reported_fact']),
      proposedEntries: parseEntries(json['proposed_entries']),
      mediaAttachments: parseAttachments(json['media_attachments']),
      workingCopyUpdated: json['working_copy_updated'] == true,
    );
  }
}

class DeckContributionsPage {
  const DeckContributionsPage({
    required this.contributions,
    this.total = 0,
    this.hasMore = false,
  });

  final List<DeckContribution> contributions;
  final int total;
  final bool hasMore;
}
