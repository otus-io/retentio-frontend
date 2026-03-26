/// EMA-style blend for mic visualization (matches toolbar reactive mic).
double smoothRecorderVisualizationLevel(
  double previousLevel,
  double rawSample,
) {
  return (previousLevel * 0.55 + rawSample * 0.45).clamp(0.0, 1.0);
}
