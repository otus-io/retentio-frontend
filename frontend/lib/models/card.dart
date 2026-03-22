// To parse this JSON data, do
//
//     final cardDetail = cardDetailFromJson(jsonString);

import 'dart:convert';

CardDetail cardDetailFromJson(String str) =>
    CardDetail.fromJson(json.decode(str));

String cardDetailToJson(CardDetail data) => json.encode(data.toJson());

class CardDetail {
  Card? card;
  num urgency;

  CardDetail({required this.card, required this.urgency});

  CardDetail copyWith({Card? card, double? urgency}) =>
      CardDetail(card: card ?? this.card, urgency: urgency ?? this.urgency);

  factory CardDetail.fromJson(Map<String, dynamic> json) => CardDetail(
    card: json['card'] == null || json['card'] is! Map
        ? null
        : Card.fromJson(json['card']),
    urgency: json["urgency"]??0,
  );

  Map<String, dynamic> toJson() => {"card": card?.toJson(), "urgency": urgency};
}

class Card {
  List<Back> back;
  int createdAt;
  int dueDate;
  String factId;
  List<Back> front;
  bool hidden;
  String id;
  int lastReview;
  List<List<int>> template;

  Card({
    required this.back,
    required this.createdAt,
    required this.dueDate,
    required this.factId,
    required this.front,
    required this.hidden,
    required this.id,
    required this.lastReview,
    required this.template,
  });

  Card copyWith({
    List<Back>? back,
    int? createdAt,
    int? dueDate,
    String? factId,
    List<Back>? front,
    bool? hidden,
    String? id,
    int? lastReview,
    List<List<int>>? template,
  }) => Card(
    back: back ?? this.back,
    createdAt: createdAt ?? this.createdAt,
    dueDate: dueDate ?? this.dueDate,
    factId: factId ?? this.factId,
    front: front ?? this.front,
    hidden: hidden ?? this.hidden,
    id: id ?? this.id,
    lastReview: lastReview ?? this.lastReview,
    template: template ?? this.template,
  );

  factory Card.fromJson(Map<String, dynamic> json) => Card(
    back: List<Back>.from(json["back"].map((x) => Back.fromJson(x))),
    createdAt: json["created_at"],
    dueDate: json["due_date"],
    factId: json["fact_id"],
    front: List<Back>.from(json["front"].map((x) => Back.fromJson(x))),
    hidden: json["hidden"],
    id: json["id"],
    lastReview: json["last_review"],
    template: List<List<int>>.from(
      json["template"].map((x) => List<int>.from(x.map((x) => x))),
    ),
  );

  Map<String, dynamic> toJson() => {
    "back": List<dynamic>.from(back.map((x) => x.toJson())),
    "created_at": createdAt,
    "due_date": dueDate,
    "fact_id": factId,
    "front": List<dynamic>.from(front.map((x) => x.toJson())),
    "hidden": hidden,
    "id": id,
    "last_review": lastReview,
    "template": List<dynamic>.from(
      template.map((x) => List<dynamic>.from(x.map((x) => x))),
    ),
  };
}

class Back {
  String? field;
  String? text;
  String? image;
  String? audio;
  String? video;

  Back({this.field, this.text, this.image, this.audio, this.video});

  factory Back.fromJson(Map<String, dynamic> json) => Back(
    field: json["field"],
    text: json["text"],
    image: json["image"],
    audio: json["audio"],
    video: json["video"],
  );

  Map<String, dynamic> toJson() => {
    "text": text,
    "image": image,
    "audio": audio,
    "video": video,
  };
}
