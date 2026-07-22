import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class Tag {
  const Tag({
    @JsonKey(defaultValue: '') required this.id,
    @JsonKey(defaultValue: '') required this.name,
    @JsonKey(defaultValue: '') required this.description,
    @JsonKey(name: 'deck_count', defaultValue: 0) this.deckCount = 0,
    @JsonKey(name: 'fact_count', defaultValue: 0) this.factCount = 0,
    @JsonKey(name: 'used_on', defaultValue: <String>[]) this.usedOn = const [],
  });

  final String id;
  final String name;
  final String description;

  /// Present on `GET /api/tags` list items only.
  final int deckCount;

  /// Present on `GET /api/tags` list items only.
  final int factCount;

  /// `"deck"` and/or `"fact"` when associated; empty when unused.
  final List<String> usedOn;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
  Map<String, dynamic> toJson() => _$TagToJson(this);
}

/// Row from `GET /api/tags/{tagId}/facts`.
class TagFactRef {
  const TagFactRef({required this.deckId, required this.factId});

  final String deckId;
  final String factId;

  factory TagFactRef.fromJson(Map<String, dynamic> json) {
    return TagFactRef(
      deckId: json['deck_id']?.toString() ?? '',
      factId: json['fact_id']?.toString() ?? '',
    );
  }
}
