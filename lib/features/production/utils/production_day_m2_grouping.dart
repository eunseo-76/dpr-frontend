import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/utils/production_overview_grouping.dart';

class ProductionM2DayRow {
  final int clientId;
  final String clientName;
  final int processId;
  final String processName;
  final double? result;
  final double? wip;
  final double? amount;
  final int clientGroupIndex; // ProductionOverviewTable과 동일하게, 업체 셀 병합에 사용

  ProductionM2DayRow({
    required this.clientId,
    required this.clientName,
    required this.processId,
    required this.processName,
    this.result,
    this.wip,
    this.amount,
    required this.clientGroupIndex,
  });
}

List<ProductionM2DayRow> buildM2DayRows(
  List<Production> productions, {
  required int m2UnitId,
}) {
  final matches = productions
      .where((p) =>
          p.unitId == m2UnitId && ((p.result ?? 0) != 0 || (p.wipResult ?? 0) != 0))
      .toList();

  matches.sort((a, b) {
    final byClient = a.clientId.compareTo(b.clientId);
    if (byClient != 0) return byClient;
    return a.processId.compareTo(b.processId);
  });

  final clientMerged = sameAsPrevious(matches, (p) => p.clientId);
  int clientGroupIdx = -1;
  return List.generate(matches.length, (i) {
    if (!clientMerged[i]) clientGroupIdx++;
    final p = matches[i];
    return ProductionM2DayRow(
      clientId: p.clientId,
      clientName: p.clientNickname ?? p.clientName,
      processId: p.processId,
      processName: p.processNickname ?? p.processName,
      result: p.result,
      wip: p.wipResult,
      amount: p.amount,
      clientGroupIndex: clientGroupIdx,
    );
  });
}
