enum ComparisonDirection { up, down, flat, unavailable }

class ComparisonDiff {
  final String label;
  final ComparisonDirection direction;
  final double? percent;

  const ComparisonDiff(this.label, this.direction, {this.percent});
}

ComparisonDiff computeDiff(double? a, double? b) {
  if (a == null || b == null || b == 0) {
    return const ComparisonDiff('-', ComparisonDirection.unavailable);
  }
  final percent = (a - b) / b * 100;
  if (percent > 0) {
    return ComparisonDiff(
      '▲${percent.toStringAsFixed(1)}%',
      ComparisonDirection.up,
      percent: percent,
    );
  }
  if (percent < 0) {
    return ComparisonDiff(
      '▼${(-percent).toStringAsFixed(1)}%',
      ComparisonDirection.down,
      percent: percent,
    );
  }
  return const ComparisonDiff('0.0%', ComparisonDirection.flat, percent: 0);
}
