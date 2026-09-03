import 'package:fprs_frontend/features/production/models/production.dart';
import 'package:fprs_frontend/features/production/models/production_overview.dart';
import 'package:fprs_frontend/features/production_comparison/models/process_metric_row.dart';

List<ProcessMetricRow> groupDayMetrics({
  required List<Production> productionsA,
  required List<Production> productionsB,
  required int factoryId,
  required String unit,
  required Map<int, String> processNames,
}) {
  final byProcessA = _groupByProcess(productionsA, factoryId);
  final byProcessB = _groupByProcess(productionsB, factoryId);

  return {...byProcessA.keys, ...byProcessB.keys}.map((processId) {
    final rowsA = byProcessA[processId] ?? const <Production>[];
    final rowsB = byProcessB[processId] ?? const <Production>[];

    return ProcessMetricRow(
      processId: processId,
      processName: processNames[processId] ?? (rowsA.isNotEmpty ? rowsA : rowsB).first.processName,
      resultA: _sumResult(rowsA, unit),
      resultB: _sumResult(rowsB, unit),
      wipA: _sumWip(rowsA, unit),
      wipB: _sumWip(rowsB, unit),
      amountA: _sumAmounts(rowsA.map((p) => p.amount)),
      amountB: _sumAmounts(rowsB.map((p) => p.amount)),
    );
  }).toList();
}

List<ProcessMetricRow> groupCumulativeMetrics({
  required List<ProcessSummaryEntry> summaryA,
  required List<ProcessSummaryEntry> summaryB,
  required String unit,
  required Map<int, String> processNames,
}) {
  final byProcessA = _groupSummaryByProcess(summaryA);
  final byProcessB = _groupSummaryByProcess(summaryB);

  return {...byProcessA.keys, ...byProcessB.keys}.map((processId) {
    final entriesA = byProcessA[processId] ?? const <ProcessSummaryEntry>[];
    final entriesB = byProcessB[processId] ?? const <ProcessSummaryEntry>[];

    return ProcessMetricRow(
      processId: processId,
      processName:
          processNames[processId] ?? (entriesA.isNotEmpty ? entriesA : entriesB).first.processName,
      resultA: _sumSummaryResult(entriesA, unit),
      resultB: _sumSummaryResult(entriesB, unit),
      wipA: null,
      wipB: null,
      amountA: _sumAmounts(entriesA.map((e) => e.amount)),
      amountB: _sumAmounts(entriesB.map((e) => e.amount)),
    );
  }).toList();
}

Map<int, List<Production>> _groupByProcess(List<Production> productions, int factoryId) {
  final map = <int, List<Production>>{};
  for (final p in productions) {
    if (p.factoryId != factoryId) continue;
    map.putIfAbsent(p.processId, () => []).add(p);
  }
  return map;
}

Map<int, List<ProcessSummaryEntry>> _groupSummaryByProcess(List<ProcessSummaryEntry> entries) {
  final map = <int, List<ProcessSummaryEntry>>{};
  for (final e in entries) {
    map.putIfAbsent(e.processId, () => []).add(e);
  }
  return map;
}

double? _sumResult(List<Production> rows, String unit) {
  final matches = rows.where((p) => p.unitName.toUpperCase() == unit.toUpperCase());
  if (matches.isEmpty) return null;
  return matches.fold<double>(0, (sum, p) => sum + (p.result ?? 0));
}

double? _sumWip(List<Production> rows, String unit) {
  final matches = rows.where((p) => p.unitName.toUpperCase() == unit.toUpperCase());
  if (matches.isEmpty) return null;
  return matches.fold<double>(0, (sum, p) => sum + (p.wipResult ?? 0));
}

double? _sumSummaryResult(List<ProcessSummaryEntry> entries, String unit) {
  final matches = entries.where((e) => e.unitName.toUpperCase() == unit.toUpperCase());
  if (matches.isEmpty) return null;
  return matches.fold<double>(0, (sum, e) => sum + e.result);
}

double? _sumAmounts(Iterable<double?> amounts) {
  final present = amounts.whereType<double>();
  if (present.isEmpty) return null;
  return present.reduce((a, b) => a + b);
}
