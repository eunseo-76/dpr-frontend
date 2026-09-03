enum ComparisonDirection { up, down, flat, unavailable }

class ComparisonDiff {
  final String label;
  final ComparisonDirection direction;

  const ComparisonDiff(this.label, this.direction);
}

ComparisonDiff computeDiff(double? a, double? b) {
  if (a == null || b == null || b == 0) {
    return const ComparisonDiff('-', ComparisonDirection.unavailable);
  }
  final percent = (a - b) / b * 100;
  if (percent > 0) {
    return ComparisonDiff('▲${percent.toStringAsFixed(1)}%', ComparisonDirection.up);
  }
  if (percent < 0) {
    return ComparisonDiff('▼${(-percent).toStringAsFixed(1)}%', ComparisonDirection.down);
  }
  return const ComparisonDiff('0.0%', ComparisonDirection.flat);
}
