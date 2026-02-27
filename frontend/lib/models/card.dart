import 'package:equatable/equatable.dart';

class CardDetail extends Equatable {
  final Card card;
  final double urgency;

  const CardDetail({required this.card, required this.urgency});

  factory CardDetail.fromJson(Map<String, dynamic> json) => CardDetail(
    card: Card.fromJson(json["card"]),
    urgency: json["urgency"]?.toDouble(),
  );

  Map<String, dynamic> toJson() => {"card": card.toJson(), "urgency": urgency};

  CardDetail? copyWith({Fact? fact}) {
    return CardDetail(
      card: card.copyWith(fact: fact),
      urgency: urgency,
    );
  }

  @override
  List<Object?> get props => [card, urgency];
}

class Card extends Equatable {
  final int createdAt;
  final int dueDate;
  final String factId;
  final bool hidden;
  final String id;
  final int lastReview;
  final List<List<int>> template;
  final Fact? fact;

  const Card({
    required this.createdAt,
    required this.dueDate,
    required this.factId,
    required this.hidden,
    required this.id,
    required this.lastReview,
    required this.template,
    this.fact,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    List<List<int>> t = [];
    final raw = json['template'];
    if (raw is List) {
      for (final row in raw) {
        if (row is List) {
          t.add([for (final x in row) (x as num).toInt()]);
        }
      }
    }
    if (t.length != 2) {
      t = [
        [0],
        [1],
      ];
    }
    return Card(
      createdAt: json["created_at"] as int? ?? 0,
      dueDate: json["due_date"] as int? ?? 0,
      factId: json["fact_id"] as String? ?? '',
      hidden: json["hidden"] as bool? ?? false,
      id: json["id"] as String? ?? '',
      lastReview: json["last_review"] as int? ?? 0,
      template: t,
    );
  }

  Map<String, dynamic> toJson() => {
    "created_at": createdAt,
    "due_date": dueDate,
    "fact_id": factId,
    "hidden": hidden,
    "id": id,
    "last_review": lastReview,
    "template": template,
    "fact": fact?.toJson(),
  };

  /// 是否需要复习（到期时间小于当前时间）
  bool get isDue {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return dueDate <= now && !hidden;
  }

  /// 是否是新卡片（从未复习过）
  bool get isNew => lastReview == 0;

  /// 获取卡片正面内容（通常是第一个 fact）
  String get front => fact!.fields.isNotEmpty ? fact!.fields[0] : '';

  /// 获取卡片背面内容（通常是第二个 fact）
  String get back => fact!.fields.length > 1 ? fact!.fields[1] : '';

  /// 是否被隐藏
  bool get isHidden => hidden;

  Card copyWith({Fact? fact}) {
    return Card(
      createdAt: createdAt,
      dueDate: dueDate,
      factId: factId,
      hidden: hidden,
      id: id,
      lastReview: lastReview,
      template: template,
      fact: fact,
    );
  }

  @override
  List<Object?> get props => [id, factId, fact];
}

class Fact extends Equatable {
  final List<String> fields;
  final String id;

  const Fact({required this.fields, required this.id});

  factory Fact.fromJson(Map<String, dynamic> json) => Fact(
    fields: List<String>.from(json["fields"].map((x) => x)),
    id: json["id"],
  );

  Map<String, dynamic> toJson() => {
    "fields": List<dynamic>.from(fields.map((x) => x)),
    "id": id,
  };

  @override
  List<Object?> get props => [fields, id];
}
