class CardDetail {
  final String factId;
  final int templateIndex;
  final int lastReview;
  final int dueDate;
  final bool hidden;
  final int minInterval;
  final int maxInterval;

  CardDetail({
    required this.factId,
    required this.templateIndex,
    required this.lastReview,
    required this.dueDate,
    required this.hidden,
    required this.minInterval,
    required this.maxInterval,
  });

  factory CardDetail.fromJson(Map<String, dynamic> json) {
    return CardDetail(
      factId: json['fact_id'] as String? ?? '',
      templateIndex: json['template_index'] as int? ?? 0,
      lastReview: json['last_review'] as int? ?? 0,
      dueDate: json['due_date'] as int? ?? 0,
      hidden: json['hidden'] as bool? ?? false,
      minInterval: json['min_interval'] as int? ?? 0,
      maxInterval: json['max_interval'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'fact_id': factId,
      'template_index': templateIndex,
      'last_review': lastReview,
      'due_date': dueDate,
      'hidden': hidden,
      'min_interval': minInterval,
      'max_interval': maxInterval,
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
  final int maxInterval;
  final int minInterval;
  final double urgency;

  Card({
    required this.card,
    required this.cardIndex,
    required this.maxInterval,
    required this.minInterval,
    required this.urgency,
  });

  factory Card.fromJson(Map<String, dynamic> json) {
    // 检查是否是简化版（直接包含 CardDetail 字段）还是完整版（嵌套 card 对象）
    final bool isSimplified =
        json.containsKey('fact_id') && !json.containsKey('card');

    if (isSimplified) {
      // 简化版：直接使用顶层的 CardDetail 字段
      final cardDetail = CardDetail.fromJson(json);
      return Card(
        card: cardDetail,
        cardIndex: json['card_index'] as int? ?? 0,
        maxInterval: cardDetail.maxInterval,
        minInterval: cardDetail.minInterval,
        urgency: (json['urgency'] as num?)?.toDouble() ?? 0.0,
      );
    } else {
      // 完整版：使用嵌套的 card 对象
      final cardDetail = CardDetail.fromJson(
        json['card'] as Map<String, dynamic>,
      );
      return Card(
        card: cardDetail,
        cardIndex: json['card_index'] as int? ?? 0,
        maxInterval: cardDetail.maxInterval,
        minInterval: cardDetail.minInterval,
        urgency: (json['urgency'] as num?)?.toDouble() ?? 0.0,
      );
    }
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
