 import 'package:fprs_frontend/features/client/models/factory_client.dart';
import 'package:fprs_frontend/features/unit/models/unit.dart';
import 'package:fprs_frontend/features/utility/models/factory_process.dart';

class ProductionRowScaffold {
  final int rowGroupId;
  final String rowGroupName;
  final String shift;
  final int unitId;
  final String unitName;

  ProductionRowScaffold({
    required this.rowGroupId,
    required this.rowGroupName,
    required this.shift,
    required this.unitId,
    required this.unitName,
  });
}

class ProductionGroupScaffold {
  final int groupId;
  final String groupName;
  final List<ProductionRowScaffold> rows;

  ProductionGroupScaffold({
    required this.groupId,
    required this.groupName,
    required this.rows,
  });
}

List<ProductionGroupScaffold> buildProductionScaffold({
  required List<FactoryProcess> factoryProcesses,
  required List<FactoryClient> factoryClients,
  required List<Unit> units,
  required String groupBy,
}) {
  final processes = <int, String>{};
  for (final fp in factoryProcesses) {
    processes.putIfAbsent(fp.processId, () => fp.processNickname ?? fp.processName);
  }

  final clients = <int, String>{};
  for (final fc in factoryClients) {
    clients.putIfAbsent(fc.clientId, () => fc.clientNickname ?? fc.clientName);
  }

  List<ProductionRowScaffold> buildRows(Map<int, String> rowGroups) {
    final rows = <ProductionRowScaffold>[];
    for (final entry in rowGroups.entries) {
      for (final shift in ['주', '야']) {
        for (final unit in units) {
          rows.add(ProductionRowScaffold(
            rowGroupId: entry.key,
            rowGroupName: entry.value,
            shift: shift,
            unitId: unit.id,
            unitName: unit.name,
          ));
        }
      }
    }
    return rows;
  }

  if (groupBy == 'process') {
    return processes.entries
        .map((e) => ProductionGroupScaffold(
              groupId: e.key,
              groupName: e.value,
              rows: buildRows(clients),
            ))
        .toList();
  } else {
    return clients.entries
        .map((e) => ProductionGroupScaffold(
              groupId: e.key,
              groupName: e.value,
              rows: buildRows(processes),
            ))
        .toList();
  }
}