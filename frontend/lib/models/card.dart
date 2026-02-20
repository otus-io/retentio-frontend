class CardDetail {
  final String factId;
  final int templateIndex;
  final int lastReview;
  final int dueDate;
  final bool hidden;

  CardDetail({
    required this.factId,
    required this.templateIndex,
    required this.lastReview,
    required this.dueDate,
    required this.hidden,
  });

  factory CardDetail.fromJson(Map<String, dynamic> json) {
    return CardDetail(
      factId: json['fact_id'] as String? ?? '',
      templateIndex: json['template_index'] as int? ?? 0,
      lastReview: json['last_review'] as int? ?? 0,
      dueDate: json['due_date'] as int? ?? 0,
      hidden: json['hidden'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fact_id': factId,
      'template_index': templateIndex,
      'last_review': lastReview,
      'due_date': dueDate,
      'hidden': hidden,
    };
  }

  /// 是否需要复习（到期时间小于当前时间）
  bool get isDue {
    final now = DateTime.now().millisecondsSinceEpoch ~/ 1000;
    return dueDate <= now && !hidden;
  }

  /// 是否是新卡片（从未复习过）
  bool get isNew => lastReview == 0;
}

class Card {
  final CardDetail card;
  final int cardIndex;
  final double urgency;

  Card({
    required this.card,
    required this.cardIndex,
    required this.urgency,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    final bool isSimplified =
        json.containsKey('fact_id') && !json.containsKey('card');

    final cardDetail = isSimplified
        ? CardDetail.fromJson(json)
        : CardDetail.fromJson(json['card'] as Map<String, dynamic>);

    return Card(
      card: cardDetail,
      cardIndex: json['card_index'] as int? ?? 0,
      urgency: (json['urgency'] as num?)?.toDouble() ?? 0.0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'card': card.toJson(), 'card_index': cardIndex, 'urgency': urgency};
  }

  /// 是否需要复习
  bool get isDue => card.isDue;

  /// 是否是新卡片
  bool get isNew => card.isNew;

  /// 是否被隐藏
  bool get isHidden => card.hidden;
}
