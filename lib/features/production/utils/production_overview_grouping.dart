import 'package:dpr_frontend/features/production/models/production_overview.dart';

class OverviewTableRow {
  final String clientName;
  final String processName;
  final String unitName;
  final double result;
  final int clientGroupIndex; // 같은 값이면 같은 업체 그룹 (표에서 셀 병합에 사용)

  OverviewTableRow({
    required this.clientName,
    required this.processName,
    required this.unitName,
    required this.result,
    required this.clientGroupIndex,
  });
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

List<OverviewTableRow> buildOverviewTableRows(
  List<ProductionOverviewRow> rows, {
  required Map<int, String> clientNames,
  required Map<int, String> processNames,
  required Map<int, String> unitNames,
}) {
  final sorted = [...rows]..sort((a, b) {
    final byClient = a.clientId.compareTo(b.clientId);
    if (byClient != 0) return byClient;
    return a.processId.compareTo(b.processId);
  });

  final merged = sameAsPrevious(sorted, (r) => r.clientId);

  int groupIndex = -1;
  return List.generate(sorted.length, (i) {
    if (!merged[i]) groupIndex++;
    final r = sorted[i];
    return OverviewTableRow(
      clientName: clientNames[r.clientId] ?? r.clientName,
      processName: processNames[r.processId] ?? r.processName,
      unitName: unitNames[r.unitId] ?? r.unitName,
      result: r.result,
      clientGroupIndex: groupIndex,
    );
  });
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
