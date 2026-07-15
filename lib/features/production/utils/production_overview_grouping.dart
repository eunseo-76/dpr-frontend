import 'package:dpr_frontend/features/production/models/production_overview.dart';

class OverviewPivotRow {
  final int clientId;
  final String clientName;
  final int processId;
  final String processName;
  final Map<int, double> resultByUnit; // unitId -> 실적
  final int clientGroupIndex; // 같은 값이면 같은 업체 그룹 (표에서 셀 병합에 사용)

  OverviewPivotRow({
    required this.clientId,
    required this.clientName,
    required this.processId,
    required this.processName,
    required this.resultByUnit,
    required this.clientGroupIndex,
  });
}

class OverviewUnitColumn {
  final int unitId;
  final String unitName;

  OverviewUnitColumn({required this.unitId, required this.unitName});
}

class OverviewPivotData {
  final List<OverviewPivotRow> rows;
  final List<OverviewUnitColumn> unitColumns;

  OverviewPivotData({required this.rows, required this.unitColumns});
}

class ProcessSummaryDisplayEntry {
  final String processName; // 같은 공정이 연속되면 빈 문자열
  final String unitName;
  final double result;
  final bool isNewProcessGroup;

  ProcessSummaryDisplayEntry({
    required this.processName,
    required this.unitName,
    required this.result,
    required this.isNewProcessGroup,
  });
}

// items[i]가 바로 앞(items[i-1])과 key가 같으면 true를 담은 리스트를 반환
// true = 이전 행과 같은 그룹이니 라벨을 비워도 된다는 뜻
List<bool> sameAsPrevious<T>(List<T> items, Object Function(T item) keyOf) {
  return List.generate(
    items.length,
    (i) => i > 0 && keyOf(items[i]) == keyOf(items[i - 1]),
  );
}

OverviewPivotData buildOverviewPivotRows(
  List<ProductionOverviewRow> rows, {
  required Map<int, String> clientNames,
  required Map<int, String> processNames,
  required Map<int, String> unitNames,
  required List<int> unitOrder,
}) {
  final grouped = <String, List<ProductionOverviewRow>>{};
  for (final r in rows) {
    grouped.putIfAbsent('${r.clientId}_${r.processId}', () => []).add(r);
  }

  final entries = grouped.values.toList()
    ..sort((a, b) {
      final byClient = a.first.clientId.compareTo(b.first.clientId);
      if (byClient != 0) return byClient;
      return a.first.processId.compareTo(b.first.processId);
    });

  final clientMerged = sameAsPrevious(entries, (e) => e.first.clientId);

  int clientGroupIdx = -1;
  final pivotRows = List.generate(entries.length, (i) {
    if (!clientMerged[i]) clientGroupIdx++;
    final group = entries[i];
    final first = group.first;
    return OverviewPivotRow(
      clientId: first.clientId,
      clientName: clientNames[first.clientId] ?? first.clientName,
      processId: first.processId,
      processName: processNames[first.processId] ?? first.processName,
      resultByUnit: {for (final r in group) r.unitId: r.result},
      clientGroupIndex: clientGroupIdx,
    );
  });

  int unitRank(int unitId) {
    final index = unitOrder.indexOf(unitId);
    return index == -1 ? unitOrder.length : index;
  }

  final dataUnitNames = {for (final r in rows) r.unitId: r.unitName};
  final presentUnitIds = rows.map((r) => r.unitId).toSet().toList()
    ..sort((a, b) => unitRank(a).compareTo(unitRank(b)));
  final unitColumns = presentUnitIds
      .map((id) => OverviewUnitColumn(
            unitId: id,
            unitName: unitNames[id] ?? dataUnitNames[id] ?? '',
          ))
      .toList();

  return OverviewPivotData(rows: pivotRows, unitColumns: unitColumns);
}

List<ProcessSummaryDisplayEntry> buildProcessSummaryDisplay(
  List<ProcessSummaryEntry> entries, {
  required Map<int, String> processNames,
  required Map<int, String> unitNames,
  required List<int> unitOrder,
}) {
  int unitRank(int unitId) {
    final index = unitOrder.indexOf(unitId);
    return index == -1 ? unitOrder.length : index;
  }

  final sorted = [...entries]..sort((a, b) {
    final byProcess = a.processId.compareTo(b.processId);
    if (byProcess != 0) return byProcess;
    return unitRank(a.unitId).compareTo(unitRank(b.unitId));
  });

  final merged = sameAsPrevious(sorted, (e) => e.processId);

  return List.generate(sorted.length, (i) {
    final e = sorted[i];
    return ProcessSummaryDisplayEntry(
      processName: merged[i] ? '' : (processNames[e.processId] ?? e.processName),
      unitName: unitNames[e.unitId] ?? e.unitName,
      result: e.result,
      isNewProcessGroup: !merged[i],
    );
  });
}
