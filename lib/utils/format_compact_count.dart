/// Compact display for large counts with two decimal places
/// (e.g. 1234 → `1.23k`, 1500000 → `1.50M`).
String formatCompactCount(int count) {
  if (count < 1000) {
    return '$count';
  }
  const suffixes = ['k', 'M', 'B'];
  var scaled = count / 1000;
  var unit = 0;
  // Pick the suffix from the rounded value: 999999 scales to 999.999, which
  // prints as 1000.00 and belongs one unit up.
  while (unit < suffixes.length - 1 &&
      double.parse(scaled.toStringAsFixed(2)) >= 1000) {
    scaled /= 1000;
    unit += 1;
  }
  return '${scaled.toStringAsFixed(2)}${suffixes[unit]}';
}
