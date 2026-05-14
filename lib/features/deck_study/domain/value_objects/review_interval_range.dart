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

  static const int _minSliderIntervalSec = 60;

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

    final urgency = (nowSec - lastReview) / currentIntervalSec;
    final minRaw = urgency >= 1
        ? currentIntervalSec * 0.5
        : currentIntervalSec * ((0.5 - 1) * urgency + 1);
    final maxRaw = urgency >= 1
        ? currentIntervalSec * 4.0
        : currentIntervalSec * ((4.0 - 1) * urgency + 1);
    final minSec = max(_minSliderIntervalSec, minRaw.round());
    var maxSec = max(maxRaw.round(), minSec);
    if (maxSec <= minSec) {
      maxSec = minSec * 4;
    }
    final midSec = ((minSec + maxSec) / 2).round();

    return ReviewIntervalRange(
      minInterval: minSec.toDouble(),
      maxInterval: maxSec.toDouble(),
      midInterval: midSec.toDouble(),
      urgency: urgency,
      currentIntervalSec: currentIntervalSec,
    );
  }
}
