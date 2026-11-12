import 'package:json_annotation/json_annotation.dart';

part 'catalog_deck.g.dart';

@JsonSerializable(fieldRename: FieldRename.snake)
class CatalogDeck {
  const CatalogDeck({
    required this.id,
    required this.name,
    this.description,
    required this.owner,
    required this.fields,
    required this.publishedVersion,
    required this.factCount,
    required this.deckTagNames,
    this.publishedAt,
    this.qaVerified = false,
  });

  final String id;
  final String name;
  final String? description;
  final String owner;
  @JsonKey(defaultValue: <String>[])
  final List<String> fields;
  final int publishedVersion;
  final int factCount;
  @JsonKey(name: 'deck_tag_names', defaultValue: <String>[])
  final List<String> deckTagNames;
  final DateTime? publishedAt;

  /// The author human-verified every text/audio field of the source deck's
  /// current facts.
  @JsonKey(fromJson: _isTrue)
  final bool qaVerified;

  factory CatalogDeck.fromJson(Map<String, dynamic> json) =>
      _$CatalogDeckFromJson(json);

  Map<String, dynamic> toJson() => _$CatalogDeckToJson(this);
}

/// Only a JSON `true` counts; strings, numbers and `null` read as false.
bool _isTrue(Object? value) => value == true;
