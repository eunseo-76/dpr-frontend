import 'package:fprs_frontend/features/production/models/production.dart';

class PeriodDetailItemRow {
  final String itemLabel;
  final List<double?> values;
  final double? total;
  final double? average;

  PeriodDetailItemRow({
    required this.itemLabel,
    required this.values,
    required this.total,
    required this.average,
  });
}

class PeriodDetailProcessGroup {
  final int processId;
  final String processName;
  final List<PeriodDetailItemRow> items;

  PeriodDetailProcessGroup({
    required this.processId,
    required this.processName,
    required this.items,
  });
}

class PeriodDetailClientProcessGroup {
  final int clientId;
  final String clientName;
  final int processId;
  final String processName;
  final int clientGroupIndex;
  final List<PeriodDetailItemRow> items;

  PeriodDetailClientProcessGroup({
    required this.clientId,
    required this.clientName,
    required this.processId,
    required this.processName,
    required this.clientGroupIndex,
    required this.items,
  });
}

double? _sumOf(List<double?> values) {
  final present = values.whereType<double>().toList();
  if (present.isEmpty) return null;
  return present.reduce((a, b) => a + b);
}

double? _averageOf(List<double?> values) {
  final present = values.whereType<double>().toList();
  if (present.isEmpty) return null;
  final avg = present.reduce((a, b) => a + b) / present.length;
  return (avg * 10).round() / 10;
}

PeriodDetailItemRow _buildItemRow(String label, List<double?> values) {
  return PeriodDetailItemRow(
    itemLabel: label,
    values: values,
    total: _sumOf(values),
    average: _averageOf(values),
  );
}

List<PeriodDetailProcessGroup> groupPeriodDetailByProcess(
  List<Production> productions,
  List<String> dates, {
  required Map<int, String> processNames,
  required bool showWip,
}) {
  double? quantityOf(Production p) => showWip ? p.wipResult : p.result;
  double? amountOf(Production p) => showWip ? p.wipAmount : p.amount;

  bool hasValue(Production p) => (quantityOf(p) ?? 0) != 0;
  final matches = productions.where(hasValue).toList();

  final m2ResultByKey = <String, double>{};
  final amountByKey = <String, double>{};
  for (final p in matches) {
    final key = '${p.date}|${p.processId}';
    final quantity = quantityOf(p);
    if (p.unitName.toUpperCase() == 'M2' && quantity != null) {
      m2ResultByKey[key] = (m2ResultByKey[key] ?? 0) + quantity;
    }
    final amount = amountOf(p);
    if (amount != null) {
      amountByKey[key] = (amountByKey[key] ?? 0) + amount;
    }
  }

  final processIds = matches.map((p) => p.processId).toSet().toList()..sort();

  return processIds.map((processId) {
    final resultValues = dates.map((d) => m2ResultByKey['$d|$processId']).toList();
    final amountValues = dates.map((d) => amountByKey['$d|$processId']).toList();

    final processName = processNames[processId] ??
        matches.firstWhere((p) => p.processId == processId).processName;

    return PeriodDetailProcessGroup(
      processId: processId,
      processName: processName,
      items: [
        _buildItemRow(showWip ? '재공' : '실적', resultValues),
        _buildItemRow('금액', amountValues),
      ],
    );
  }).toList();
}

List<PeriodDetailClientProcessGroup> groupPeriodDetailByClient(
  List<Production> productions,
  List<String> dates, {
  required Map<int, String> clientNames,
  required Map<int, String> processNames,
  required bool showWip,
}) {
  double? quantityOf(Production p) => showWip ? p.wipResult : p.result;
  double? amountOf(Production p) => showWip ? p.wipAmount : p.amount;

  bool hasValue(Production p) => (quantityOf(p) ?? 0) != 0;
  final matches = productions.where(hasValue).toList();

  final m2ResultByKey = <String, double>{};
  final amountByKey = <String, double>{};
  for (final p in matches) {
    final key = '${p.date}|${p.clientId}|${p.processId}';
    final quantity = quantityOf(p);
    if (p.unitName.toUpperCase() == 'M2' && quantity != null) {
      m2ResultByKey[key] = (m2ResultByKey[key] ?? 0) + quantity;
    }
    final amount = amountOf(p);
    if (amount != null) {
      amountByKey[key] = (amountByKey[key] ?? 0) + amount;
    }
  }

  final pairs = <String, (int, int)>{
    for (final p in matches) '${p.clientId}_${p.processId}': (p.clientId, p.processId),
  };
  final sortedPairs = pairs.values.toList()
    ..sort((a, b) {
      final byClient = a.$1.compareTo(b.$1);
      if (byClient != 0) return byClient;
      return a.$2.compareTo(b.$2);
    });

  final groups = <PeriodDetailClientProcessGroup>[];
  int clientGroupIdx = -1;
  int? previousClientId;

  for (final (clientId, processId) in sortedPairs) {
    final resultValues =
        dates.map((d) => m2ResultByKey['$d|$clientId|$processId']).toList();
    final amountValues =
        dates.map((d) => amountByKey['$d|$clientId|$processId']).toList();

    if (clientId != previousClientId) {
      clientGroupIdx++;
      previousClientId = clientId;
    }

    final clientName = clientNames[clientId] ??
        matches.firstWhere((p) => p.clientId == clientId).clientName;
    final processName = processNames[processId] ??
        matches.firstWhere((p) => p.processId == processId).processName;

    groups.add(PeriodDetailClientProcessGroup(
      clientId: clientId,
      clientName: clientName,
      processId: processId,
      processName: processName,
      clientGroupIndex: clientGroupIdx,
      items: [
        _buildItemRow(showWip ? '재공' : '실적', resultValues),
        _buildItemRow('금액', amountValues),
      ],
    ));
  }

  return groups;
}
