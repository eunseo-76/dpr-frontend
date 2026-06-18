import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/utils/production_scaffold.dart';
import 'package:dpr_frontend/features/utility/utils/utility_period_columns.dart';

class ProductionPeriodRow {
  final int rowGroupId;
  final String rowGroupName;
  final String shift;
  final int unitId;
  final String unitName;
  final List<double?> values;
  final List<double?> amounts;
  final double total;
  final double? unitPrice;

  ProductionPeriodRow({
    required this.rowGroupId,
    required this.rowGroupName,
    required this.shift,
    required this.unitId,
    required this.unitName,
    required this.values,
    List<double?>? amounts,
    required this.total,
    this.unitPrice,
  }) : amounts = amounts ?? List.filled(values.length, null);
}

class ProductionPeriodGroup {
  final int groupId;
  final String groupName;
  final List<ProductionPeriodRow> rows;
  final Map<int, double> dailySumByUnit;
  final Map<int, double> cumulativeSumByUnit;

  ProductionPeriodGroup({
    required this.groupId,
    required this.groupName,
    required this.rows,
    required this.dailySumByUnit,
    required this.cumulativeSumByUnit,
  });
}

List<PeriodColumn> weekPeriodColumns(String selectedDate) {
  final d = DateTime.parse(selectedDate);
  final monday = d.subtract(Duration(days: d.weekday - 1));
  return List.generate(7, (i) {
    final date = monday.add(Duration(days: i));
    return PeriodColumn(
      label: date.day.toString().padLeft(2, '0'),
      dates: [date.toIso8601String().substring(0, 10)],
    );
  });
}

List<ProductionPeriodGroup> groupProductionsForPeriod(
  List<Production> productions,
  List<ProductionGroupScaffold> scaffold,
  List<PeriodColumn> columns,
  String groupBy,
) {
  final Map<String, Production> byKey = {
    for (final p in productions)
      '${p.processId}|${p.clientId}|${p.unitId}|${p.date}': p,
  };

  final Map<String, double?> amountByKey = {
    for (final p in productions)
      '${p.processId}|${p.clientId}|${p.unitId}|${p.date}': p.amount,
  };

  String lookupKey(int groupId, ProductionRowScaffold row, String date) {
    return groupBy == '공정별'
        ? '$groupId|${row.rowGroupId}|${row.unitId}|$date'
        : '${row.rowGroupId}|$groupId|${row.unitId}|$date';
  }

  return scaffold.map((group) {
    final unitRows = group.rows.map((rowScaffold) {
      final values = columns.map((column) {
        double? sum;
        for (final date in column.dates) {
          final p = byKey[lookupKey(group.groupId, rowScaffold, date)];
          final v = rowScaffold.shift == '주' ? p?.dayShift : p?.nightShift;
          if (v != null) sum = (sum ?? 0) + v;
        }
        return sum;
      }).toList();

      final amounts = columns.map((column) {
        double? sum;
        for (final date in column.dates) {
          final a = amountByKey[lookupKey(group.groupId, rowScaffold, date)];
          if (a != null) sum = (sum ?? 0) + a;
        }
        return sum;
      }).toList();

      Production? anyProd;
      for (final col in columns) {
        for (final date in col.dates) {
          anyProd = byKey[lookupKey(group.groupId, rowScaffold, date)];
          if (anyProd != null) break;
        }
        if (anyProd != null) break;
      }

      return ProductionPeriodRow(
        rowGroupId: rowScaffold.rowGroupId,
        rowGroupName: rowScaffold.rowGroupName,
        shift: rowScaffold.shift,
        unitId: rowScaffold.unitId,
        unitName: rowScaffold.unitName,
        values: values,
        amounts: amounts,
        total: values.fold(0.0, (a, b) => a + (b ?? 0.0)),
        unitPrice: anyProd?.unitPrice,
      );
    }).toList();

    final rows = _injectAmountRows(unitRows, columns.length);

    final cardProductions = productions.where((p) => groupBy == '공정별'
        ? p.processId == group.groupId
        : p.clientId == group.groupId
    ).toList();
    final dailySums = <int, double>{};
    final cumulativeSums = <int, double>{};
    for (final p in cardProductions) {
      dailySums[p.unitId] = (dailySums[p.unitId] ?? 0) + (p.result ?? 0);
      cumulativeSums[p.unitId] =
          (cumulativeSums[p.unitId] ?? 0) + (p.cumulativeResult ?? 0);
    }

    return ProductionPeriodGroup(
      groupId: group.groupId,
      groupName: group.groupName,
      rows: rows,
      dailySumByUnit: dailySums,
      cumulativeSumByUnit: cumulativeSums,
    );
  }).toList();
}

List<ProductionPeriodRow> _injectAmountRows(
    List<ProductionPeriodRow> unitRows, int columnCount) {
  final result = <ProductionPeriodRow>[];
  int i = 0;
  while (i < unitRows.length) {
    final groupId = unitRows[i].rowGroupId;
    final shift = unitRows[i].shift;

    final shiftRows = <ProductionPeriodRow>[];
    while (i < unitRows.length &&
        unitRows[i].rowGroupId == groupId &&
        unitRows[i].shift == shift) {
      shiftRows.add(unitRows[i]);
      i++;
    }

    result.addAll(shiftRows);

    final amountValues = List.generate(columnCount, (col) {
      double? sum;
      for (final r in shiftRows) {
        final a = r.amounts[col];
        if (a != null) sum = (sum ?? 0) + a;
      }
      return sum;
    });

    result.add(ProductionPeriodRow(
      rowGroupId: groupId,
      rowGroupName: shiftRows.first.rowGroupName,
      shift: shift,
      unitId: -1,
      unitName: '금액',
      values: amountValues,
      total: amountValues.fold(0.0, (a, b) => a + (b ?? 0.0)),
    ));
  }
  return result;
}