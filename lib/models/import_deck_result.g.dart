// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'import_deck_result.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

ImportDeckResult _$ImportDeckResultFromJson(Map<String, dynamic> json) =>
    ImportDeckResult(
      id: json['id'] as String,
      sourceDeckId: json['source_deck_id'] as String,
      sourceVersion: (json['source_version'] as num).toInt(),
      importedAt: DateTime.parse(json['imported_at'] as String),
    );

Map<String, dynamic> _$ImportDeckResultToJson(ImportDeckResult instance) =>
    <String, dynamic>{
      'id': instance.id,
      'source_deck_id': instance.sourceDeckId,
      'source_version': instance.sourceVersion,
      'imported_at': instance.importedAt.toIso8601String(),
    };
