// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'fact.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

FactEntry _$FactEntryFromJson(Map<String, dynamic> json) => FactEntry(
  text: json['text'] as String? ?? '',
  audio: json['audio'] as String? ?? '',
  image: json['image'] as String? ?? '',
  video: json['video'] as String? ?? '',
  json: json['json'] as String? ?? '',
);

Map<String, dynamic> _$FactEntryToJson(FactEntry instance) => <String, dynamic>{
  'text': instance.text,
  'audio': instance.audio,
  'image': instance.image,
  'video': instance.video,
  'json': instance.json,
};

Fact _$FactFromJson(Map<String, dynamic> json) => Fact(
  id: json['id'] as String? ?? '',
  entries:
      (json['entries'] as List<dynamic>?)
          ?.map((e) => FactEntry.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  fields:
      (json['fields'] as List<dynamic>?)?.map((e) => e as String).toList() ??
      [],
);

Map<String, dynamic> _$FactToJson(Fact instance) => <String, dynamic>{
  'id': instance.id,
  'entries': instance.entries.map((e) => e.toJson()).toList(),
  'fields': instance.fields,
};
