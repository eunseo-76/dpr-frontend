class ProcessMetricRow {
  final int processId;
  final String processName;
  final double? resultA;
  final double? resultB;
  final double? amountA;
  final double? amountB;

  const ProcessMetricRow({
    required this.processId,
    required this.processName,
    required this.resultA,
    required this.resultB,
    required this.amountA,
    required this.amountB,
  });
}
