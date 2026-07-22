import 'package:dpr_frontend/features/production/models/production.dart';

class ProductionM2DayRow {
  final int clientId;
  final String clientName;
  final int processId;
  final String processName;
  final double? result;
  final double? wip;

  ProductionM2DayRow({
    required this.clientId,
    required this.clientName,
    required this.processId,
    required this.processName,
    this.result,
    this.wip,
  });
}

List<ProductionM2DayRow> buildM2DayRows(
  List<Production> productions, {
  required int m2UnitId,
}) {
  final rows = productions
      .where((p) =>
          p.unitId == m2UnitId && ((p.result ?? 0) != 0 || (p.wipResult ?? 0) != 0))
      .map((p) => ProductionM2DayRow(
            clientId: p.clientId,
            clientName: p.clientNickname ?? p.clientName,
            processId: p.processId,
            processName: p.processNickname ?? p.processName,
            result: p.result,
            wip: p.wipResult,
          ))
      .toList();

  rows.sort((a, b) {
    final byClient = a.clientId.compareTo(b.clientId);
    if (byClient != 0) return byClient;
    return a.processId.compareTo(b.processId);
  });

  return rows;
}
