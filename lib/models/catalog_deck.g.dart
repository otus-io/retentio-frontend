// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'catalog_deck.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CatalogDeck _$CatalogDeckFromJson(Map<String, dynamic> json) => CatalogDeck(
  id: json['id'] as String,
  name: json['name'] as String,
  description: json['description'] as String?,
  owner: json['owner'] as String,
  fields:
      (json['fields'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
  publishedVersion: (json['published_version'] as num).toInt(),
  factCount: (json['fact_count'] as num).toInt(),
  deckTagNames:
      (json['deck_tag_names'] as List<dynamic>?)
          ?.map((e) => e as String)
          .toList() ??
      [],
  publishedAt: json['published_at'] == null
      ? null
      : DateTime.parse(json['published_at'] as String),
);

Map<String, dynamic> _$CatalogDeckToJson(CatalogDeck instance) =>
    <String, dynamic>{
      'id': instance.id,
      'name': instance.name,
      'description': instance.description,
      'owner': instance.owner,
      'fields': instance.fields,
      'published_version': instance.publishedVersion,
      'fact_count': instance.factCount,
      'deck_tag_names': instance.deckTagNames,
      'published_at': instance.publishedAt?.toIso8601String(),
    };
