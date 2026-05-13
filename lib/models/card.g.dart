// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'card.dart';

// **************************************************************************
// JsonSerializableGenerator
// **************************************************************************

CardDetail _$CardDetailFromJson(Map<String, dynamic> json) => CardDetail(
  card: Card.fromJson(json['card'] as Map<String, dynamic>),
  urgency: json['urgency'] as num? ?? 0,
);

Map<String, dynamic> _$CardDetailToJson(CardDetail instance) =>
    <String, dynamic>{
      'card': instance.card.toJson(),
      'urgency': instance.urgency,
    };

Card _$CardFromJson(Map<String, dynamic> json) => Card(
  back:
      (json['back'] as List<dynamic>?)
          ?.map((e) => CardSlot.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  createdAt: (json['created_at'] as num?)?.toInt() ?? 0,
  dueDate: (json['due_date'] as num?)?.toInt() ?? 0,
  factId: json['fact_id'] as String? ?? '',
  front:
      (json['front'] as List<dynamic>?)
          ?.map((e) => CardSlot.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
  hidden: json['hidden'] as bool? ?? false,
  id: json['id'] as String? ?? '',
  lastReview: (json['last_review'] as num?)?.toInt() ?? 0,
  template:
      (json['template'] as List<dynamic>?)
          ?.map(
            (e) => (e as List<dynamic>).map((e) => (e as num).toInt()).toList(),
          )
          .toList() ??
      [],
);

Map<String, dynamic> _$CardToJson(Card instance) => <String, dynamic>{
  'back': instance.back.map((e) => e.toJson()).toList(),
  'created_at': instance.createdAt,
  'due_date': instance.dueDate,
  'fact_id': instance.factId,
  'front': instance.front.map((e) => e.toJson()).toList(),
  'hidden': instance.hidden,
  'id': instance.id,
  'last_review': instance.lastReview,
  'template': instance.template,
};

CardSlot _$CardSlotFromJson(Map<String, dynamic> json) => CardSlot(
  field: json['field'] as String? ?? 'Text',
  items:
      (json['items'] as List<dynamic>?)
          ?.map((e) => Item.fromJson(e as Map<String, dynamic>))
          .toList() ??
      [],
);

Map<String, dynamic> _$CardSlotToJson(CardSlot instance) => <String, dynamic>{
  'field': instance.field,
  'items': instance.items.map((e) => e.toJson()).toList(),
};

Item _$ItemFromJson(Map<String, dynamic> json) => Item(
  type: json['type'] as String? ?? '',
  value: json['value'] as String? ?? '',
);

Map<String, dynamic> _$ItemToJson(Item instance) => <String, dynamic>{
  'type': instance.type,
  'value': instance.value,
};
