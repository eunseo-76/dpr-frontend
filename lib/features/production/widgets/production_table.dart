import 'package:data_table_2/data_table_2.dart';
import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';
import 'package:flutter/material.dart';

class ProductionTable extends StatelessWidget {
  final List<Unit> units;
  final List<Production> productions;
  final bool isProcessView;

  const ProductionTable({
    super.key,
    required this.units,
    required this.productions,
    required this.isProcessView,
  });

  @override
  Widget build(BuildContext context) {
    final Map<int, Map<int, Map<int, Production>>> grouped = {};
    for (final p in productions) {
      grouped.putIfAbsent(p.processId, () => {});
      grouped[p.processId]!.putIfAbsent(p.clientId, () => {});
      grouped[p.processId]![p.clientId]![p.unitId] = p;
    }

    final rows = <DataRow2>[];
    grouped.forEach((processId, clients) {
      final processName = productions
          .firstWhere((p) => p.processId == processId)
          .processName;

      clients.forEach((clientId, unitMap) {
        final clientName = productions
            .firstWhere((p) => p.clientId == clientId)
            .clientName;

        rows.add(DataRow2(cells: [
          DataCell(Text(processName)),
          DataCell(Text(clientName)),
          DataCell(const Text('주간')),
          ...units.map((u) => DataCell(
            Text(unitMap[u.id]?.dayShift?.toString() ?? '-'),
          )),
        ]));

        rows.add(DataRow2(cells: [
          const DataCell(Text('')),
          const DataCell(Text('')),
          DataCell(const Text('야간')),
          ...units.map((u) => DataCell(
            Text(unitMap[u.id]?.nightShift?.toString() ?? '-'),
          )),
        ]));
      });
    });

    return DataTable2(
      fixedLeftColumns: 3,
      minWidth: 400,
      columnSpacing: 4,
      columns: [
        const DataColumn2(label: Text('공정'), fixedWidth: 50),
        const DataColumn2(label: Text('업체'), fixedWidth: 90),
        const DataColumn2(label: Text('주/야'), fixedWidth: 45),
        ...units.map((u) => DataColumn2(label: Text(u.name))),
      ],
      rows: rows,
    );
  }
}
