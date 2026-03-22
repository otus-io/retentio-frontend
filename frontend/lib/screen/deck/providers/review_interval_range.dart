/// Result of [computeReviewIntervalRange]: bounds for the next review interval
/// slider (seconds, whole numbers), derived from urgency.
typedef ReviewIntervalRange = ({
  double minInterval,
  double maxInterval,
  double midInterval,
  double urgency,
  int currentIntervalSec,
});

/// All timestamps are Unix seconds (UTC instant).
///
/// When [dueDate] <= [lastReview], the scheduling window is invalid; returns
/// zeros so the caller can avoid dividing by zero.
ReviewIntervalRange computeReviewIntervalRange({
  required int nowSec,
  required int lastReview,
  required int dueDate,
}) {
  final currentIntervalSec = dueDate - lastReview;
  if (currentIntervalSec <= 0) {
    return (
      minInterval: 0.0,
      maxInterval: 0.0,
      midInterval: 0.0,
      urgency: 0.0,
      currentIntervalSec: currentIntervalSec,
    );
  }

  final urgency = (nowSec - lastReview) / currentIntervalSec;
  final minRaw = urgency >= 1
      ? currentIntervalSec * 0.5
      : currentIntervalSec * ((0.5 - 1) * urgency + 1);
  final maxRaw = urgency >= 1
      ? currentIntervalSec * 4.0
      : currentIntervalSec * ((4.0 - 1) * urgency + 1);
  final minSec = minRaw.round();
  final maxSec = maxRaw.round();
  final midSec = ((minRaw + maxRaw) / 2).round();

  return (
    minInterval: minSec.toDouble(),
    maxInterval: maxSec.toDouble(),
    midInterval: midSec.toDouble(),
    urgency: urgency,
    currentIntervalSec: currentIntervalSec,
  );
}
