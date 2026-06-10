import 'package:json_annotation/json_annotation.dart';

part 'tag.g.dart';

@JsonSerializable()
class Tag {
  const Tag({
    @JsonKey(defaultValue: '') required this.id,
    @JsonKey(defaultValue: '') required this.name,
    @JsonKey(defaultValue: '') required this.description,
  });

  final String id;
  final String name;
  final String description;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);
  Map<String, dynamic> toJson() => _$TagToJson(this);
}
