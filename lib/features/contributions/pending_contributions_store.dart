import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Client-side contribution outbox for imported decks (pending + sent history).
enum PendingContributionKind {
  edit,
  add,
  deckTags,
  factTags,
  template,
  fieldRename,
  report,
}

extension PendingContributionKindX on PendingContributionKind {
  String get wireName => switch (this) {
    PendingContributionKind.edit => 'edit',
    PendingContributionKind.add => 'add',
    PendingContributionKind.deckTags => 'deck_tags',
    PendingContributionKind.factTags => 'fact_tags',
    PendingContributionKind.template => 'template',
    PendingContributionKind.fieldRename => 'field_rename',
    PendingContributionKind.report => 'report',
  };

  static PendingContributionKind? tryParse(String? raw) {
    return switch (raw) {
      'edit' => PendingContributionKind.edit,
      'add' => PendingContributionKind.add,
      'deck_tags' => PendingContributionKind.deckTags,
      'fact_tags' => PendingContributionKind.factTags,
      'template' => PendingContributionKind.template,
      'field_rename' => PendingContributionKind.fieldRename,
      'report' => PendingContributionKind.report,
      _ => null,
    };
  }
}

class PendingContributionItem {
  const PendingContributionItem({
    required this.id,
    required this.kind,
    required this.savedAt,
    this.factId,
    this.preview,
    this.addTags,
    this.removeTags,
    this.proposedFields,
    this.message,
  });

  final String id;
  final PendingContributionKind kind;
  final DateTime savedAt;
  final String? factId;
  final String? preview;
  final List<String>? addTags;
  final List<String>? removeTags;
  final List<String>? proposedFields;
  final String? message;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.wireName,
    'savedAt': savedAt.toIso8601String(),
    if (factId != null) 'factId': factId,
    if (preview != null) 'preview': preview,
    if (addTags != null) 'addTags': addTags,
    if (removeTags != null) 'removeTags': removeTags,
    if (proposedFields != null) 'proposedFields': proposedFields,
    if (message != null) 'message': message,
  };

  factory PendingContributionItem.fromJson(Map<String, dynamic> json) {
    final kind =
        PendingContributionKindX.tryParse(json['kind']?.toString()) ??
        PendingContributionKind.edit;
    return PendingContributionItem(
      id: json['id']?.toString() ?? '',
      kind: kind,
      savedAt:
          DateTime.tryParse(json['savedAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      factId: json['factId']?.toString(),
      preview: json['preview']?.toString(),
      addTags: _stringList(json['addTags']),
      removeTags: _stringList(json['removeTags']),
      proposedFields: _stringList(json['proposedFields']),
      message: json['message']?.toString(),
    );
  }

  static List<String>? _stringList(dynamic raw) {
    if (raw is! List) return null;
    return raw.map((e) => e.toString()).toList();
  }
}

class SentContributionItem {
  const SentContributionItem({
    required this.id,
    required this.kind,
    required this.sentAt,
    this.factId,
    this.preview,
    this.message,
    this.contributionId,
  });

  final String id;
  final PendingContributionKind kind;
  final DateTime sentAt;
  final String? factId;
  final String? preview;
  final String? message;
  final String? contributionId;

  Map<String, dynamic> toJson() => {
    'id': id,
    'kind': kind.wireName,
    'sentAt': sentAt.toIso8601String(),
    if (factId != null) 'factId': factId,
    if (preview != null) 'preview': preview,
    if (message != null) 'message': message,
    if (contributionId != null) 'contributionId': contributionId,
  };

  factory SentContributionItem.fromJson(Map<String, dynamic> json) {
    final kind =
        PendingContributionKindX.tryParse(json['kind']?.toString()) ??
        PendingContributionKind.edit;
    return SentContributionItem(
      id: json['id']?.toString() ?? '',
      kind: kind,
      sentAt:
          DateTime.tryParse(json['sentAt']?.toString() ?? '') ??
          DateTime.fromMillisecondsSinceEpoch(0),
      factId: json['factId']?.toString(),
      preview: json['preview']?.toString(),
      message: json['message']?.toString(),
      contributionId: json['contributionId']?.toString(),
    );
  }
}

class PendingContributionsStore {
  PendingContributionsStore._();
  static final PendingContributionsStore of = PendingContributionsStore._();

  static const _pendingPrefix = 'retentio_pending_contribs_v2:';
  static const _sentPrefix = 'retentio_sent_contribs_v1:';

  String _pendingKey(String deckId) => '$_pendingPrefix$deckId';
  String _sentKey(String deckId) => '$_sentPrefix$deckId';

  String itemId(PendingContributionKind kind, {String? factId}) {
    if (kind == PendingContributionKind.deckTags ||
        kind == PendingContributionKind.fieldRename) {
      return kind.wireName;
    }
    if (factId != null && factId.isNotEmpty) {
      return '${kind.wireName}:$factId';
    }
    return kind.wireName;
  }

  Future<List<PendingContributionItem>> listPending(String deckId) async {
    final items = await _readPending(deckId);
    items.sort((a, b) => b.savedAt.compareTo(a.savedAt));
    return items;
  }

  Future<int> countPending(String deckId) async {
    return (await _readPending(deckId)).length;
  }

  Future<List<SentContributionItem>> listSent(String deckId) async {
    final items = await _readSent(deckId);
    items.sort((a, b) => b.sentAt.compareTo(a.sentAt));
    return items;
  }

  Future<List<PendingContributionItem>> upsert({
    required String deckId,
    required PendingContributionKind kind,
    String? factId,
    String? preview,
    List<String>? addTags,
    List<String>? removeTags,
    List<String>? proposedFields,
    String? message,
    String? id,
  }) async {
    final pendingId = id ?? itemId(kind, factId: factId);
    final next = PendingContributionItem(
      id: pendingId,
      kind: kind,
      factId: factId,
      preview: preview,
      addTags: addTags,
      removeTags: removeTags,
      proposedFields: proposedFields,
      message: message,
      savedAt: DateTime.now().toUtc(),
    );
    final prev = await _readPending(deckId);
    final filtered = prev.where((r) => r.id != pendingId).toList();
    await _writePending(deckId, [next, ...filtered]);
    return listPending(deckId);
  }

  Future<List<PendingContributionItem>> remove(
    String deckId,
    String pendingId,
  ) async {
    final next = (await _readPending(
      deckId,
    )).where((r) => r.id != pendingId).toList();
    await _writePending(deckId, next);
    return listPending(deckId);
  }

  Future<void> clearPending(String deckId) async {
    await _writePending(deckId, []);
  }

  /// Moves a pending row into sent history.
  ///
  /// Not atomic across SharedPreferences keys: read pending → remove pending →
  /// write sent are separate writes. If the process dies between remove and
  /// write-sent, the staged item can be lost.
  Future<void> markAsSent(
    String deckId,
    String pendingId, {
    String? contributionId,
    String? message,
  }) async {
    final pendingList = await _readPending(deckId);
    PendingContributionItem? pending;
    for (final r in pendingList) {
      if (r.id == pendingId) {
        pending = r;
        break;
      }
    }
    await remove(deckId, pendingId);
    if (pending == null) return;
    final row = SentContributionItem(
      id: '${pending.kind.wireName}:${pending.factId ?? 'deck'}:${DateTime.now().millisecondsSinceEpoch}',
      kind: pending.kind,
      factId: pending.factId,
      preview: pending.preview,
      message: message ?? pending.message,
      contributionId: contributionId,
      sentAt: DateTime.now().toUtc(),
    );
    final sent = [row, ...await _readSent(deckId)].take(200).toList();
    await _writeSent(deckId, sent);
  }

  static String? previewFromEntryTexts(Iterable<String> texts) {
    for (final raw in texts) {
      final t = raw.trim();
      if (t.isEmpty) continue;
      if (t.length <= 80) return t;
      return '${t.substring(0, 77)}…';
    }
    return null;
  }

  Future<List<PendingContributionItem>> _readPending(String deckId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_pendingKey(deckId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (e) =>
                PendingContributionItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writePending(
    String deckId,
    List<PendingContributionItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _pendingKey(deckId);
    if (items.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(
      key,
      json.encode(items.map((e) => e.toJson()).toList()),
    );
  }

  Future<List<SentContributionItem>> _readSent(String deckId) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_sentKey(deckId));
    if (raw == null || raw.isEmpty) return [];
    try {
      final decoded = json.decode(raw);
      if (decoded is! List) return [];
      return decoded
          .whereType<Map>()
          .map(
            (e) => SentContributionItem.fromJson(Map<String, dynamic>.from(e)),
          )
          .where((e) => e.id.isNotEmpty)
          .toList();
    } catch (_) {
      return [];
    }
  }

  Future<void> _writeSent(
    String deckId,
    List<SentContributionItem> items,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _sentKey(deckId);
    if (items.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(
      key,
      json.encode(items.map((e) => e.toJson()).toList()),
    );
  }
}
