import 'package:fprs_frontend/features/production/models/production.dart';
import 'package:fprs_frontend/features/production/models/production_overview.dart';

class OverviewPivotRow {
  final int clientId;
  final String clientName;
  final int processId;
  final String processName;
  final Map<int, double> resultByUnit; // unitId -> 실적
  final double? totalAmount;
  final int clientGroupIndex; // 같은 값이면 같은 업체 그룹 (표에서 셀 병합에 사용)

  OverviewPivotRow({
    required this.clientId,
    required this.clientName,
    required this.processId,
    required this.processName,
    required this.resultByUnit,
    this.totalAmount,
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

class UnitResultDisplay {
  final double result;
  final String unitName;
  // 일별보기 업체별 합계에서만 채워짐 (기간별보기는 재공을 누적할 근거가 없어 비워둠)
  final double? wip;

  UnitResultDisplay({required this.result, required this.unitName, this.wip});
}

class ProcessSummaryDisplayEntry {
  final String processName;
  final List<UnitResultDisplay> unitResults;
  final double? totalAmount; // 단위별 금액을 전부 합친 값 (단가가 월중 바뀌면 여러 단위에 동시에 금액이 잡힐 수 있음)

  ProcessSummaryDisplayEntry({
    required this.processName,
    required this.unitResults,
    this.totalAmount,
  });
}

class ClientSummaryDisplayEntry {
  final String clientName;
  final String processName;
  final List<UnitResultDisplay> unitResults;
  final double? totalAmount;
  final int clientGroupIndex; // 같은 값이면 같은 업체 그룹 (표에서 셀 병합에 사용)

  ClientSummaryDisplayEntry({
    required this.clientName,
    required this.processName,
    required this.unitResults,
    this.totalAmount,
    required this.clientGroupIndex,
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
  final resultRows = rows.where((r) => r.result != 0).toList();

  final grouped = <String, List<ProductionOverviewRow>>{};
  for (final r in resultRows) {
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
    final amounts = group.map((r) => r.amount).whereType<double>().toList();

    // 기간 안에 같은 단위가 여러 날짜에 걸쳐 나올 수 있어 날짜별로 더한다
    // (그냥 Map으로 덮어쓰면 마지막 날짜 값만 남는 버그가 있었음).
    final resultByUnit = <int, double>{};
    for (final r in group) {
      resultByUnit[r.unitId] = (resultByUnit[r.unitId] ?? 0) + r.result;
    }

    return OverviewPivotRow(
      clientId: first.clientId,
      clientName: clientNames[first.clientId] ?? first.clientName,
      processId: first.processId,
      processName: processNames[first.processId] ?? first.processName,
      resultByUnit: resultByUnit,
      totalAmount: amounts.isEmpty ? null : amounts.reduce((a, b) => a + b),
      clientGroupIndex: clientGroupIdx,
    );
  });

  int unitRank(int unitId) {
    final index = unitOrder.indexOf(unitId);
    return index == -1 ? unitOrder.length : index;
  }

  final dataUnitNames = {for (final r in resultRows) r.unitId: r.unitName};
  final presentUnitIds = resultRows.map((r) => r.unitId).toSet().toList()
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

  final grouped = <int, List<ProcessSummaryEntry>>{};
  for (final e in entries) {
    grouped.putIfAbsent(e.processId, () => []).add(e);
  }

  final processIds = grouped.keys.toList()..sort();

  return processIds.map((processId) {
    final group = grouped[processId]!
      ..sort((a, b) => unitRank(a.unitId).compareTo(unitRank(b.unitId)));

    final unitResults = group
        .where((e) => e.result != 0)
        .map((e) => UnitResultDisplay(
              result: e.result,
              unitName: unitNames[e.unitId] ?? e.unitName,
            ))
        .toList();

    final amounts = group.map((e) => e.amount).whereType<double>().toList();

    return ProcessSummaryDisplayEntry(
      processName: processNames[processId] ?? group.first.processName,
      unitResults: unitResults,
      totalAmount: amounts.isEmpty ? null : amounts.reduce((a, b) => a + b),
    );
  }).toList();
}

// buildProcessSummaryDisplay와 같은 공정 단위 그루핑이지만, 일별보기 전용이다.
// 서버 집계(ProcessSummaryEntry)엔 재공 필드가 없어서, 하루치 원본 리스트
// (_productions, Production 모델)를 직접 그룹핑해 재공까지 함께 보여준다.
// 기간별보기는 이 함수를 쓰지 않는다 — buildClientSummaryDisplayFromProductions와 동일한 이유
// (여러 날짜에 걸친 재공 합산은 재고 관점에서 아직 의미가 정리되지 않음).
List<ProcessSummaryDisplayEntry> buildProcessSummaryDisplayFromProductions(
  List<Production> productions, {
  required Map<int, String> processNames,
  required Map<int, String> unitNames,
  required List<int> unitOrder,
}) {
  int unitRank(int unitId) {
    final index = unitOrder.indexOf(unitId);
    return index == -1 ? unitOrder.length : index;
  }

  bool hasValue(Production p) => (p.result ?? 0) != 0 || (p.wipResult ?? 0) != 0;

  final matches = productions.where(hasValue).toList();

  final grouped = <int, List<Production>>{};
  for (final p in matches) {
    grouped.putIfAbsent(p.processId, () => []).add(p);
  }

  final processIds = grouped.keys.toList()..sort();

  return processIds.map((processId) {
    final group = grouped[processId]!;

    // 업체별 표와 달리 공정 단위로 묶으므로, 같은 단위가 여러 업체에
    // 걸쳐 나올 수 있어 단위별로 합산해야 한다.
    final resultByUnit = <int, double>{};
    final wipByUnit = <int, double>{};
    final unitNameById = <int, String>{};
    for (final p in group) {
      resultByUnit[p.unitId] = (resultByUnit[p.unitId] ?? 0) + (p.result ?? 0);
      wipByUnit[p.unitId] = (wipByUnit[p.unitId] ?? 0) + (p.wipResult ?? 0);
      unitNameById[p.unitId] = p.unitName;
    }
    final unitIds = resultByUnit.keys
        .where((id) => resultByUnit[id] != 0 || wipByUnit[id] != 0)
        .toList()
      ..sort((a, b) => unitRank(a).compareTo(unitRank(b)));
    final unitResults = unitIds
        .map((id) => UnitResultDisplay(
              result: resultByUnit[id]!,
              unitName: unitNames[id] ?? unitNameById[id]!,
              wip: wipByUnit[id],
            ))
        .toList();

    final amounts = group.map((p) => p.amount).whereType<double>().toList();

    return ProcessSummaryDisplayEntry(
      processName: processNames[processId] ?? group.first.processName,
      unitResults: unitResults,
      totalAmount: amounts.isEmpty ? null : amounts.reduce((a, b) => a + b),
    );
  }).toList();
}

// buildOverviewPivotRows와 같은 (업체, 공정) 단위 그루핑을 그대로 따른다 —
// [업체별 실적 합계] 표가 업체 안에서도 공정별로 행을 나눠 보여주고 있으므로,
// 상세 바텀시트에서 공정을 합쳐버리면 원본 표와 어긋난다.
List<ClientSummaryDisplayEntry> buildClientSummaryDisplay(
  List<ProductionOverviewRow> rows, {
  required Map<int, String> clientNames,
  required Map<int, String> processNames,
  required Map<int, String> unitNames,
  required List<int> unitOrder,
}) {
  int unitRank(int unitId) {
    final index = unitOrder.indexOf(unitId);
    return index == -1 ? unitOrder.length : index;
  }

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
  return List.generate(entries.length, (i) {
    if (!clientMerged[i]) clientGroupIdx++;
    final group = entries[i];
    final first = group.first;

    // 기간 안에 같은 단위가 여러 날짜에 걸쳐 나올 수 있어 날짜별로 더한다
    // (예전엔 행을 그냥 나열만 해서 같은 단위가 여러 줄로 중복되는 버그가 있었음).
    final resultByUnit = <int, double>{};
    final unitNameById = <int, String>{};
    for (final r in group) {
      resultByUnit[r.unitId] = (resultByUnit[r.unitId] ?? 0) + r.result;
      unitNameById[r.unitId] = r.unitName;
    }
    final unitIds = resultByUnit.keys
        .where((id) => resultByUnit[id] != 0)
        .toList()
      ..sort((a, b) => unitRank(a).compareTo(unitRank(b)));
    final unitResults = unitIds
        .map((id) => UnitResultDisplay(
              result: resultByUnit[id]!,
              unitName: unitNames[id] ?? unitNameById[id]!,
            ))
        .toList();

    final amounts = group.map((r) => r.amount).whereType<double>().toList();

    return ClientSummaryDisplayEntry(
      clientName: clientNames[first.clientId] ?? first.clientName,
      processName: processNames[first.processId] ?? first.processName,
      unitResults: unitResults,
      totalAmount: amounts.isEmpty ? null : amounts.reduce((a, b) => a + b),
      clientGroupIndex: clientGroupIdx,
    );
  });
}

// buildClientSummaryDisplay와 동일한 (업체, 공정) 그루핑이지만, 일별보기 전용이다.
// ProductionOverviewRow(서버 집계용 DTO)엔 재공 필드가 없어서, 하루치 원본 리스트
// (_productions, Production 모델)를 직접 그룹핑해 재공까지 함께 보여준다.
// 기간별보기는 이 함수를 쓰지 않는다 — 여러 날짜의 재공을 더하는 게 재고 관점에서
// 의미가 있는지 아직 정리되지 않았기 때문 (2026-07-27 kenny공 결정).
List<ClientSummaryDisplayEntry> buildClientSummaryDisplayFromProductions(
  List<Production> productions, {
  required Map<int, String> clientNames,
  required Map<int, String> processNames,
  required Map<int, String> unitNames,
  required List<int> unitOrder,
}) {
  int unitRank(int unitId) {
    final index = unitOrder.indexOf(unitId);
    return index == -1 ? unitOrder.length : index;
  }

  bool hasValue(Production p) => (p.result ?? 0) != 0 || (p.wipResult ?? 0) != 0;

  final matches = productions.where(hasValue).toList();

  final grouped = <String, List<Production>>{};
  for (final p in matches) {
    grouped.putIfAbsent('${p.clientId}_${p.processId}', () => []).add(p);
  }

  final entries = grouped.values.toList()
    ..sort((a, b) {
      final byClient = a.first.clientId.compareTo(b.first.clientId);
      if (byClient != 0) return byClient;
      return a.first.processId.compareTo(b.first.processId);
    });

  final clientMerged = sameAsPrevious(entries, (e) => e.first.clientId);

  int clientGroupIdx = -1;
  return List.generate(entries.length, (i) {
    if (!clientMerged[i]) clientGroupIdx++;
    final group = entries[i]
      ..sort((a, b) => unitRank(a.unitId).compareTo(unitRank(b.unitId)));
    final first = group.first;

    final unitResults = group
        .map((p) => UnitResultDisplay(
              result: p.result ?? 0,
              unitName: unitNames[p.unitId] ?? p.unitName,
              wip: p.wipResult,
            ))
        .toList();

    final amounts = group.map((p) => p.amount).whereType<double>().toList();

    return ClientSummaryDisplayEntry(
      clientName: clientNames[first.clientId] ?? first.clientName,
      processName: processNames[first.processId] ?? first.processName,
      unitResults: unitResults,
      totalAmount: amounts.isEmpty ? null : amounts.reduce((a, b) => a + b),
      clientGroupIndex: clientGroupIdx,
    );
  });
}
