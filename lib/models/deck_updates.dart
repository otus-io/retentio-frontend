import 'package:retentio/models/fact.dart';

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
  });

  final int sourceVersion;
  final int latestVersion;
  final List<DeckUpdateFactRef> addedFacts;
  final List<DeckUpdateFactRef> removedFacts;
  final List<DeckUpdateEditedFact> editedFacts;
  final List<DeckUpdateMediaChange> mediaChanges;
  final List<DeckUpdateCardTemplateChange> cardTemplateChanges;

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

    int? toInt(dynamic v) {
      if (v is int) return v;
      if (v is num) return v.toInt();
      if (v is String) return int.tryParse(v);
      return null;
    }

    return DeckUpdatesResult(
      sourceVersion: toInt(data['source_version']) ?? 0,
      latestVersion: toInt(data['latest_version']) ?? 0,
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
    );
  }

  /// Defaults matching web-test / backend: removed → keep if overlay else accept;
  /// edited → accept if aligned else keep.
  Map<String, SyncFactDecisionAction> defaultDecisions() {
    final out = <String, SyncFactDecisionAction>{};
    for (final f in removedFacts) {
      if (f.defaultAction == 'keep') {
        out[f.factId] = SyncFactDecisionAction.keep;
      } else if (f.defaultAction == 'accept') {
        out[f.factId] = SyncFactDecisionAction.accept;
      } else {
        out[f.factId] = (f.hasLocalOverlay || f.local)
            ? SyncFactDecisionAction.keep
            : SyncFactDecisionAction.accept;
      }
    }
    for (final f in editedFacts) {
      out[f.factId] = f.aligned
          ? SyncFactDecisionAction.accept
          : SyncFactDecisionAction.keep;
    }
    return out;
  }
}
