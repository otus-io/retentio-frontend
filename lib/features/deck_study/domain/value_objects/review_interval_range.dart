import 'dart:math' show max;

class ReviewIntervalRange {
  const ReviewIntervalRange({
    required this.minInterval,
    required this.maxInterval,
    required this.midInterval,
    required this.urgency,
    required this.currentIntervalSec,
  });

  final double minInterval;
  final double maxInterval;
  final double midInterval;
  final double urgency;
  final int currentIntervalSec;

  static const int _minIntervalSec = 300;
  static const double _minFactor = 0.5;
  static const double _maxFactor = 4.0;
  static const double _defFactor = 2.0;

  /// All timestamps are Unix seconds (UTC instant).
  ///
  /// When [dueDate] <= [lastReview], the scheduling window is invalid; returns
  /// zeros so the caller can avoid dividing by zero.
  static ReviewIntervalRange fromTimestamps({
    required int nowSec,
    required int lastReview,
    required int dueDate,
  }) {
    final currentIntervalSec = dueDate - lastReview;
    if (currentIntervalSec <= 0) {
      return const ReviewIntervalRange(
        minInterval: 0,
        maxInterval: 0,
        midInterval: 0,
        urgency: 0,
        currentIntervalSec: 0,
      );
    }

    final intervalSec = max(_minIntervalSec, currentIntervalSec);
    final urgency = (nowSec - lastReview) / intervalSec;
    final minRaw = urgency >= 1
        ? intervalSec * _minFactor
        : intervalSec * ((_minFactor - 1) * urgency + 1);
    final maxRaw = urgency >= 1
        ? intervalSec * _maxFactor
        : intervalSec * ((_maxFactor - 1) * urgency + 1);
    final defRaw = urgency >= 1
        ? intervalSec * _defFactor
        : intervalSec * ((_defFactor - 1) * urgency + 1);
    final minSec = minRaw.round();
    var maxSec = max(maxRaw.round(), minSec);
    if (maxSec <= minSec) {
      maxSec = minSec * 4;
    }
    final midSec = defRaw.round().clamp(minSec, maxSec);

    return ReviewIntervalRange(
      minInterval: minSec.toDouble(),
      maxInterval: maxSec.toDouble(),
      midInterval: midSec.toDouble(),
      urgency: urgency,
      currentIntervalSec: currentIntervalSec,
    );
  }
}
