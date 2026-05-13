import 'package:json_annotation/json_annotation.dart';

part 'fact.g.dart';

/// Fact payload from GET/PATCH `/api/decks/{id}/facts/{factId}`.
@JsonSerializable()
class FactEntry {
  const FactEntry({
    @JsonKey(defaultValue: '') this.text = '',
    @JsonKey(defaultValue: '') this.audio = '',
    @JsonKey(defaultValue: '') this.image = '',
    @JsonKey(defaultValue: '') this.video = '',
    @JsonKey(defaultValue: '') this.json = '',
  });

  final String text;
  final String audio;
  final String image;
  final String video;
  final String json;

  factory FactEntry.fromJson(Map<String, dynamic> json) =>
      _$FactEntryFromJson(json);

  FactEntry copyWithText(String newText) => FactEntry(
    text: newText,
    audio: audio,
    image: image,
    video: video,
    json: json,
  );

  /// JSON for PATCH `entries` (preserves media when non-empty).
  Map<String, dynamic> toJson() {
    final m = _$FactEntryToJson(this);
    m.removeWhere(
      (key, value) => key != 'text' && value is String && value.isEmpty,
    );
    return m;
  }
}

@JsonSerializable(explicitToJson: true)
class Fact {
  const Fact({
    @JsonKey(defaultValue: '') required this.id,
    @JsonKey(defaultValue: <FactEntry>[]) required this.entries,
    @JsonKey(defaultValue: <String>[]) required this.fields,
  });

  final String id;
  final List<FactEntry> entries;
  final List<String> fields;

  factory Fact.fromJson(Map<String, dynamic> json) =>
      _$FactFromJson(_normalizeFactJson(json));

  Map<String, dynamic> toJson() => _$FactToJson(this);

  /// Body for PATCH update-fact; `fields` only if same length as [entries].
  Map<String, dynamic> toUpdateBody() {
    final body = <String, dynamic>{
      'entries': entries.map((e) => e.toJson()).toList(),
    };
    if (fields.length == entries.length) {
      body['fields'] = fields;
    }
    return body;
  }

  /// Replaces text per slot; keeps audio/image/video from the original entries.
  Fact withMergedTexts(List<String> texts) {
    if (texts.length != entries.length) {
      throw ArgumentError(
        'texts.length (${texts.length}) must equal entries.length (${entries.length})',
      );
    }
    final merged = List<FactEntry>.generate(
      entries.length,
      (i) => entries[i].copyWithText(texts[i]),
    );
    return Fact(id: id, entries: merged, fields: fields);
  }
}

Map<String, dynamic> _normalizeFactJson(Map<String, dynamic> raw) {
  final json = Map<String, dynamic>.from(raw);

  final entriesRaw = json['entries'];
  if (entriesRaw is List) {
    json['entries'] = entriesRaw
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .toList();
  } else {
    json['entries'] = <Map<String, dynamic>>[];
  }

  final fieldsRaw = json['fields'];
  if (fieldsRaw is List) {
    json['fields'] = fieldsRaw.map((e) => e?.toString() ?? '').toList();
  } else {
    json['fields'] = <String>[];
  }

  return json;
}
