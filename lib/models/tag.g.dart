// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'tag.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

Tag _$TagFromJson(Map<String, dynamic> json) => Tag(
  id: json['id'] as String? ?? '',
  name: json['name'] as String? ?? '',
  description: json['description'] as String? ?? '',
  deckCount: (json['deck_count'] as num?)?.toInt() ?? 0,
  factCount: (json['fact_count'] as num?)?.toInt() ?? 0,
  usedOn:
      (json['used_on'] as List<dynamic>?)?.map((e) => e.toString()).toList() ??
      const [],
);

Map<String, dynamic> _$TagToJson(Tag instance) => <String, dynamic>{
  'id': instance.id,
  'name': instance.name,
  'description': instance.description,
  'deck_count': instance.deckCount,
  'fact_count': instance.factCount,
  'used_on': instance.usedOn,
};
