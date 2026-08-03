/// Compact display for large counts with two decimal places
/// (e.g. 1234 → `1.23k`, 1500000 → `1.50M`).
String formatCompactCount(int count) {
  if (count < 1000) {
    return '$count';
  }
  if (count < 1000000) {
    return '${(count / 1000).toStringAsFixed(2)}k';
  }
  if (count < 1000000000) {
    return '${(count / 1000000).toStringAsFixed(2)}M';
  }
  return '${(count / 1000000000).toStringAsFixed(2)}B';
}
