/// [intervalSec] is the review interval in seconds.
String formatReviewIntervalLabel(double intervalSec) {
  const secPerMinute = 60;
  const secPerHour = 60 * secPerMinute;
  const secPerDay = 24 * secPerHour;
  const secPerMonth = 30 * secPerDay;
  const secPerYear = 12 * secPerMonth;

  if (intervalSec < secPerMinute) {
    return '${intervalSec.ceil()}s';
  }
  if (intervalSec < secPerHour) {
    return '${(intervalSec / secPerMinute).ceil()}m';
  }
  if (intervalSec < secPerDay) {
    return '${(intervalSec / secPerHour).toStringAsFixed(1)}h';
  }
  if (intervalSec < secPerMonth) {
    return '${(intervalSec / secPerDay).toStringAsFixed(1)}d';
  }
  if (intervalSec < secPerYear) {
    return '${(intervalSec / secPerMonth).toStringAsFixed(1)}mo';
  }
  return '${(intervalSec / secPerYear).toStringAsFixed(1)}y';
}
