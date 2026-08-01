import 'package:retentio/models/fact.dart';

int? _toInt(dynamic v) {
  if (v is int) return v;
  if (v is num) return v.toInt();
  if (v is String) return int.tryParse(v);
  return null;
}

Map<String, int> _parseVersions(dynamic raw) {
  if (raw is! Map) return const {};
  final out = <String, int>{};
  for (final e in raw.entries) {
    final n = _toInt(e.value);
    if (n != null && n > 0) {
      out[e.key.toString()] = n;
    }
  }
  return out;
}

/// One added/removed fact row from `GET …/updates`.
class DeckUpdateFactRef {
  const DeckUpdateFactRef({
    required this.factId,
    this.fact,
    this.hasLocalOverlay = false,
    this.local = false,
    this.aligned = false,
    this.defaultAction,
  });

  final String factId;
  final Fact? fact;
  final bool hasLocalOverlay;
  final bool local;
  final bool aligned;

  /// `"accept"` or `"keep"` when present on removals.
  final String? defaultAction;

  factory DeckUpdateFactRef.fromJson(Map<String, dynamic> json) {
    final factRaw = json['fact'];
    return DeckUpdateFactRef(
      factId: json['fact_id']?.toString() ?? '',
      fact: factRaw is Map
          ? Fact.fromJson(Map<String, dynamic>.from(factRaw))
          : null,
      hasLocalOverlay: json['has_local_overlay'] == true,
      local: json['local'] == true,
      aligned: json['aligned'] == true,
      defaultAction: json['default_action']?.toString(),
    );
  }
}

class DeckUpdateEditedFact {
  const DeckUpdateEditedFact({
    required this.factId,
    this.before,
    this.after,
    this.hasLocalOverlay = false,
    this.local = false,
    this.aligned = false,
  });

  final String factId;
  final Fact? before;
  final Fact? after;
  final bool hasLocalOverlay;
  final bool local;
  final bool aligned;

  factory DeckUpdateEditedFact.fromJson(Map<String, dynamic> json) {
    Fact? parseFact(dynamic raw) {
      if (raw is! Map) return null;
      return Fact.fromJson(Map<String, dynamic>.from(raw));
    }

    return DeckUpdateEditedFact(
      factId: json['fact_id']?.toString() ?? '',
      before: parseFact(json['before']),
      after: parseFact(json['after']),
      hasLocalOverlay: json['has_local_overlay'] == true,
      local: json['local'] == true,
      aligned: json['aligned'] == true,
    );
  }
}

class DeckUpdateMediaChange {
  const DeckUpdateMediaChange({
    required this.mediaId,
    this.beforeHash,
    this.afterHash,
  });

  final String mediaId;
  final String? beforeHash;
  final String? afterHash;

  factory DeckUpdateMediaChange.fromJson(Map<String, dynamic> json) {
    return DeckUpdateMediaChange(
      mediaId: json['media_id']?.toString() ?? '',
      beforeHash: json['before_hash']?.toString(),
      afterHash: json['after_hash']?.toString(),
    );
  }
}

class DeckUpdateCardTemplateChange {
  const DeckUpdateCardTemplateChange({required this.factId});

  final String factId;

  factory DeckUpdateCardTemplateChange.fromJson(Map<String, dynamic> json) {
    return DeckUpdateCardTemplateChange(
      factId: json['fact_id']?.toString() ?? '',
    );
  }
}

enum SyncFactDecisionAction { accept, keep }

class SyncFactDecision {
  const SyncFactDecision({required this.factId, required this.action});

  final String factId;
  final SyncFactDecisionAction action;

  Map<String, dynamic> toJson() => {
    'fact_id': factId,
    'action': action == SyncFactDecisionAction.accept ? 'accept' : 'keep',
  };
}

class DeckUpdatesResult {
  const DeckUpdatesResult({
    required this.sourceVersion,
    required this.latestVersion,
    this.addedFacts = const [],
    this.removedFacts = const [],
    this.editedFacts = const [],
    this.mediaChanges = const [],
    this.cardTemplateChanges = const [],
    this.beforeMediaVersions = const {},
    this.afterMediaVersions = const {},
  });

  final int sourceVersion;
  final int latestVersion;
  final List<DeckUpdateFactRef> addedFacts;
  final List<DeckUpdateFactRef> removedFacts;
  final List<DeckUpdateEditedFact> editedFacts;
  final List<DeckUpdateMediaChange> mediaChanges;
  final List<DeckUpdateCardTemplateChange> cardTemplateChanges;

  /// Media id → published version at [sourceVersion] (for before / removed playback).
  final Map<String, int> beforeMediaVersions;

  /// Media id → published version at [latestVersion] (for after / added playback).
  final Map<String, int> afterMediaVersions;

  /// Playable URL for a fact entry audio id (or absolute/relative URL).
  static String? mediaPlayUrl(String idOrUrl, Map<String, int> versions) {
    final v = idOrUrl.trim();
    if (v.isEmpty) return null;
    if (v.startsWith('http://') ||
        v.startsWith('https://') ||
        v.startsWith('/')) {
      return v;
    }
    final ver = versions[v];
    if (ver != null && ver > 0) {
      return '/api/media/$v?v=$ver';
    }
    return '/api/media/$v';
  }

  bool get hasContentChanges =>
      addedFacts.isNotEmpty ||
      removedFacts.isNotEmpty ||
      editedFacts.isNotEmpty ||
      mediaChanges.isNotEmpty ||
      cardTemplateChanges.isNotEmpty;

  bool get hasUpdates => latestVersion > sourceVersion || hasContentChanges;

  factory DeckUpdatesResult.fromJson(Map<String, dynamic> data) {
    List<T> parseList<T>(dynamic raw, T Function(Map<String, dynamic>) parse) {
      if (raw is! List) return [];
      return raw
          .whereType<Map>()
          .map((e) => parse(Map<String, dynamic>.from(e)))
          .toList();
    }

    final beforeMediaVersions = _parseVersions(data['before_media_versions']);
    final afterMediaVersions = _parseVersions(data['after_media_versions']);

    return DeckUpdatesResult(
      sourceVersion: _toInt(data['source_version']) ?? 0,
      latestVersion: _toInt(data['latest_version']) ?? 0,
      addedFacts: parseList(data['added_facts'], DeckUpdateFactRef.fromJson),
      removedFacts: parseList(
        data['removed_facts'],
        DeckUpdateFactRef.fromJson,
      ),
      editedFacts: parseList(
        data['edited_facts'],
        DeckUpdateEditedFact.fromJson,
      ),
      mediaChanges: parseList(
        data['media_changes'],
        DeckUpdateMediaChange.fromJson,
      ),
      cardTemplateChanges: parseList(
        data['card_template_changes'],
        DeckUpdateCardTemplateChange.fromJson,
      ),
      beforeMediaVersions: beforeMediaVersions,
      afterMediaVersions: afterMediaVersions,
    );
  }

  /// Author publish is preferred: every removed/edited fact defaults to accept.
  Map<String, SyncFactDecisionAction> defaultDecisions() {
    final out = <String, SyncFactDecisionAction>{};
    for (final f in removedFacts) {
      out[f.factId] = SyncFactDecisionAction.accept;
    }
    for (final f in editedFacts) {
      out[f.factId] = SyncFactDecisionAction.accept;
    }
    return out;
  }
}

/// Lightweight `GET …/updates?summary=1` payload (ids/counts only).
class DeckUpdatesSummary {
  const DeckUpdatesSummary({
    required this.sourceVersion,
    required this.latestVersion,
    this.addedFactIds = const [],
    this.removedFactIds = const [],
    this.editedFactIds = const [],
    this.mediaChangeCount = 0,
    this.cardTemplateChangeCount = 0,
    this.changeSummary = '',
  });

  final int sourceVersion;
  final int latestVersion;
  final List<String> addedFactIds;
  final List<String> removedFactIds;
  final List<String> editedFactIds;
  final int mediaChangeCount;
  final int cardTemplateChangeCount;
  final String changeSummary;

  bool get hasContentChanges =>
      addedFactIds.isNotEmpty ||
      removedFactIds.isNotEmpty ||
      editedFactIds.isNotEmpty ||
      mediaChangeCount > 0 ||
      cardTemplateChangeCount > 0;

  bool get hasUpdates => latestVersion > sourceVersion || hasContentChanges;

  factory DeckUpdatesSummary.fromJson(Map<String, dynamic> data) {
    List<String> ids(dynamic raw) {
      if (raw is! List) return const [];
      return raw.map((e) => e.toString()).where((s) => s.isNotEmpty).toList();
    }

    return DeckUpdatesSummary(
      sourceVersion: _toInt(data['source_version']) ?? 0,
      latestVersion: _toInt(data['latest_version']) ?? 0,
      addedFactIds: ids(data['added_fact_ids']),
      removedFactIds: ids(data['removed_fact_ids']),
      editedFactIds: ids(data['edited_fact_ids']),
      mediaChangeCount: _toInt(data['media_change_count']) ?? 0,
      cardTemplateChangeCount: _toInt(data['card_template_change_count']) ?? 0,
      changeSummary: data['change_summary']?.toString() ?? '',
    );
  }
}

enum DeckUpdateFactKind { added, removed, edited }

/// `GET …/updates/facts/{factId}` payload.
class DeckUpdateFactDetail {
  const DeckUpdateFactDetail({
    required this.factId,
    required this.kind,
    required this.sourceVersion,
    required this.latestVersion,
    this.fact,
    this.before,
    this.after,
    this.hasLocalOverlay = false,
    this.local = false,
    this.aligned = false,
    this.defaultAction,
    this.beforeMediaVersions = const {},
    this.afterMediaVersions = const {},
  });

  final String factId;
  final DeckUpdateFactKind kind;
  final int sourceVersion;
  final int latestVersion;
  final Fact? fact;
  final Fact? before;
  final Fact? after;
  final bool hasLocalOverlay;
  final bool local;
  final bool aligned;
  final String? defaultAction;
  final Map<String, int> beforeMediaVersions;
  final Map<String, int> afterMediaVersions;

  factory DeckUpdateFactDetail.fromJson(Map<String, dynamic> data) {
    Fact? parseFact(dynamic raw) {
      if (raw is! Map) return null;
      return Fact.fromJson(Map<String, dynamic>.from(raw));
    }

    final kindRaw = data['kind']?.toString().trim() ?? '';
    final DeckUpdateFactKind kind;
    switch (kindRaw) {
      case 'added':
        kind = DeckUpdateFactKind.added;
      case 'removed':
        kind = DeckUpdateFactKind.removed;
      case 'edited':
      case '':
        kind = DeckUpdateFactKind.edited;
      default:
        throw ArgumentError.value(
          data['kind'],
          'kind',
          'DeckUpdateFactDetail.fromJson: unrecognized kind',
        );
    }

    return DeckUpdateFactDetail(
      factId: data['fact_id']?.toString() ?? '',
      kind: kind,
      sourceVersion: _toInt(data['source_version']) ?? 0,
      latestVersion: _toInt(data['latest_version']) ?? 0,
      fact: parseFact(data['fact']),
      before: parseFact(data['before']),
      after: parseFact(data['after']),
      hasLocalOverlay: data['has_local_overlay'] == true,
      local: data['local'] == true,
      aligned: data['aligned'] == true,
      defaultAction: data['default_action']?.toString(),
      beforeMediaVersions: _parseVersions(data['before_media_versions']),
      afterMediaVersions: _parseVersions(data['after_media_versions']),
    );
  }
}
