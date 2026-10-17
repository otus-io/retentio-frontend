import 'package:retentio/models/fact.dart';

/// One editorial score on a fact entry aspect (`text` / `audio`).
class FactQualityAspect {
  const FactQualityAspect({required this.score, required this.model});

  final int score;
  final String model;

  bool get isHuman => model == FactQuality.humanModel;

  Map<String, dynamic> toJson() => {'score': score, 'model': model};
}

/// Quality record of one fact (`/api/decks/{id}/facts/{factId}/quality`).
class FactQuality {
  const FactQuality({required this.entries});

  static const String humanModel = 'human';
  static const int humanScore = 10;
  static const String aspectText = 'text';
  static const String aspectAudio = 'audio';

  /// Entry index → aspect name → score.
  final Map<int, Map<String, FactQualityAspect>> entries;

  factory FactQuality.fromJson(Map<String, dynamic> json) {
    final parsed = <int, Map<String, FactQualityAspect>>{};
    final raw = json['entries'];
    if (raw is Map) {
      raw.forEach((key, value) {
        final index = int.tryParse(key.toString());
        if (index == null || index < 0 || value is! Map) return;
        final aspects = <String, FactQualityAspect>{};
        for (final aspect in const [aspectText, aspectAudio]) {
          final scoreRaw = value[aspect];
          if (scoreRaw is! Map) continue;
          final score = _toInt(scoreRaw['score']);
          final model = scoreRaw['model']?.toString() ?? '';
          if (score == null || model.isEmpty) continue;
          aspects[aspect] = FactQualityAspect(score: score, model: model);
        }
        if (aspects.isNotEmpty) parsed[index] = aspects;
      });
    }
    return FactQuality(entries: parsed);
  }

  Map<String, FactQualityAspect> aspectsAt(int index) =>
      entries[index] ?? const {};
}

/// Human-verification counters from `/api/decks/{id}/quality/stats`.
class FactQualityStats {
  const FactQualityStats({
    required this.verifiedAspects,
    required this.totalAspects,
    this.lastFactId,
    this.columns = const {},
    this.cursors = const {},
  });

  final int verifiedAspects;
  final int totalAspects;

  /// Legacy deck-wide QA resume cursor; `null` when never verified.
  final String? lastFactId;

  /// Entry index → human-verification progress for that column.
  final Map<int, FactQualityColumnStats> columns;

  /// Entry index → last signed-off fact id for that column.
  final Map<int, String> cursors;

  FactQualityColumnStats? columnAt(int index) => columns[index];

  factory FactQualityStats.fromJson(Map<String, dynamic> json) {
    final resume = json['last_fact_id']?.toString();
    final columns = <int, FactQualityColumnStats>{};
    final rawColumns = json['columns'];
    if (rawColumns is Map) {
      rawColumns.forEach((key, value) {
        final index = int.tryParse(key.toString());
        if (index == null || index < 0 || value is! Map) return;
        columns[index] = FactQualityColumnStats.fromJson(
          Map<String, dynamic>.from(value),
        );
      });
    }
    final cursors = <int, String>{};
    final rawCursors = json['cursors'];
    if (rawCursors is Map) {
      rawCursors.forEach((key, value) {
        final index = int.tryParse(key.toString());
        final factId = value?.toString() ?? '';
        if (index == null || index < 0 || factId.isEmpty) return;
        cursors[index] = factId;
      });
    }
    return FactQualityStats(
      verifiedAspects: _toInt(json['verified_aspects']) ?? 0,
      totalAspects: _toInt(json['total_aspects']) ?? 0,
      lastFactId: (resume != null && resume.isNotEmpty) ? resume : null,
      columns: columns,
      cursors: cursors,
    );
  }
}

/// Resume fact for a column walk: the earliest cursor among [columns].
///
/// Returns null when any selected column has no cursor (or an unknown id), so
/// the walk starts at the first fact.
String? qaResumeFactId({
  required Set<int> columns,
  required Map<int, String> cursors,
  required List<String> factIds,
}) {
  if (columns.isEmpty || factIds.isEmpty) return null;
  int? earliest;
  String? resumeId;
  for (final col in columns) {
    final id = cursors[col];
    if (id == null || id.isEmpty) return null;
    final index = factIds.indexOf(id);
    if (index < 0) return null;
    if (earliest == null || index < earliest) {
      earliest = index;
      resumeId = id;
    }
  }
  return resumeId;
}

/// Per-column human-verification counters from quality stats.
class FactQualityColumnStats {
  const FactQualityColumnStats({
    required this.verifiedAspects,
    required this.totalAspects,
  });

  final int verifiedAspects;
  final int totalAspects;

  int get completionPercent =>
      totalAspects == 0 ? 0 : ((verifiedAspects * 100) / totalAspects).round();

  factory FactQualityColumnStats.fromJson(Map<String, dynamic> json) =>
      FactQualityColumnStats(
        verifiedAspects: _toInt(json['verified_aspects']) ?? 0,
        totalAspects: _toInt(json['total_aspects']) ?? 0,
      );
}

/// Aspects a reviewer can sign off on for one column; empty when nothing to score.
List<String> qaScoreableAspects(FactEntry entry) => [
  if (entry.text.trim().isNotEmpty) FactQuality.aspectText,
  if (entry.audio.trim().isNotEmpty) FactQuality.aspectAudio,
];

/// `entries` body for the quality PUT (whole record is replaced).
///
/// Checked columns get `human` / [FactQuality.humanScore] on every scoreable
/// aspect; other prior scores are kept except `human` ones on unchecked columns
/// (unchecking withdraws a sign-off).
Map<String, dynamic> qaMergedQualityEntries({
  FactQuality? quality,
  required List<FactEntry> entries,
  required Set<int> checkedIndexes,
  Set<int>? activeColumnIndexes,
}) {
  final merged = <String, dynamic>{};
  for (var i = 0; i < entries.length; i++) {
    if (activeColumnIndexes != null && !activeColumnIndexes.contains(i)) {
      final preserved = quality?.aspectsAt(i) ?? const {};
      if (preserved.isNotEmpty) {
        merged['$i'] = {
          for (final entry in preserved.entries)
            entry.key: entry.value.toJson(),
        };
      }
      continue;
    }
    final aspects = <String, FactQualityAspect>{};
    if (checkedIndexes.contains(i)) {
      for (final aspect in qaScoreableAspects(entries[i])) {
        aspects[aspect] = const FactQualityAspect(
          score: FactQuality.humanScore,
          model: FactQuality.humanModel,
        );
      }
    }
    quality?.aspectsAt(i).forEach((aspect, score) {
      if (aspects.containsKey(aspect) || score.isHuman) return;
      aspects[aspect] = score;
    });
    if (aspects.isNotEmpty) {
      merged['$i'] = {
        for (final entry in aspects.entries) entry.key: entry.value.toJson(),
      };
    }
  }
  return merged;
}

int? _toInt(dynamic value) {
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value);
  return null;
}
