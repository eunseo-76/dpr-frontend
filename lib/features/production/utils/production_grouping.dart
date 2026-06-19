import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/utils/production_scaffold.dart';

class ProductionDayRow {
  final int rowGroupId;
  final String rowGroupName;
  final String shift;
  final int unitId;
  final String unitName;
  final double? value;
  final double? unitPrice;
  final int? productionId;

  final double? amount;

  ProductionDayRow({
    required this.rowGroupId,
    required this.rowGroupName,
    required this.shift,
    required this.unitId,
    required this.unitName,
    this.value,
    this.unitPrice,
    this.amount,
    this.productionId,
  });
}

class ProductionDayGroup {
  final int groupId;
  final String groupName;
  final List<ProductionDayRow> rows;
  final Map<int, double> dailySumByUnit;
  final Map<int, double> cumulativeSumByUnit;

  ProductionDayGroup({
    required this.groupId,
    required this.groupName,
    required this.rows,
    required this.dailySumByUnit,
    required this.cumulativeSumByUnit,
  });
}

List<ProductionDayGroup> groupProductionsForDay(
  List<Production> productions,
  List<ProductionGroupScaffold> scaffold,
  String groupBy,
) {
  return scaffold.map((group) {
    final cardProductions = productions.where((p) =>
      groupBy == '공정별'
          ? p.processId == group.groupId
          : p.clientId == group.groupId
    ).toList();

    final unitRows = group.rows.map((rowScaffold) {
      final matches = cardProductions.where((p) =>
        (groupBy == '공정별' ? p.clientId : p.processId) == rowScaffold.rowGroupId &&
        p.unitId == rowScaffold.unitId
      );
      final production = matches.isEmpty ? null : matches.first;

      return ProductionDayRow(
        rowGroupId: rowScaffold.rowGroupId,
        rowGroupName: rowScaffold.rowGroupName,
        shift: rowScaffold.shift,
        unitId: rowScaffold.unitId,
        unitName: rowScaffold.unitName,
        value: rowScaffold.shift == '주'
            ? production?.dayShift
            : production?.nightShift,
        unitPrice: production?.unitPrice,
        amount: production?.amount,
        productionId: production?.productionId,
      );
    }).toList();

    final rows = _injectAmountRows(unitRows);

    final dailySums = <int, double>{};
    final cumulativeSums = <int, double>{};
    for (final p in cardProductions) {
      dailySums[p.unitId] = (dailySums[p.unitId] ?? 0) + (p.result ?? 0);
      cumulativeSums[p.unitId] =
          (cumulativeSums[p.unitId] ?? 0) + (p.cumulativeResult ?? 0);
    }

    return ProductionDayGroup(
      groupId: group.groupId,
      groupName: group.groupName,
      rows: rows,
      dailySumByUnit: dailySums,
      cumulativeSumByUnit: cumulativeSums,
    );
  }).toList();
}

List<ProductionDayRow> _injectAmountRows(List<ProductionDayRow> unitRows) {
  final result = <ProductionDayRow>[];
  int i = 0;
  while (i < unitRows.length) {
    final groupId = unitRows[i].rowGroupId;
    final shift = unitRows[i].shift;

    final shiftRows = <ProductionDayRow>[];
    while (i < unitRows.length &&
        unitRows[i].rowGroupId == groupId &&
        unitRows[i].shift == shift) {
      shiftRows.add(unitRows[i]);
      i++;
    }

    result.addAll(shiftRows);

    double amountSum = 0;
    bool hasAmount = false;
    for (final r in shiftRows) {
      if (r.amount != null) {
        amountSum += r.amount!;
        hasAmount = true;
      }
    }

    result.add(ProductionDayRow(
      rowGroupId: groupId,
      rowGroupName: shiftRows.first.rowGroupName,
      shift: shift,
      unitId: -1,
      unitName: '금액',
      value: hasAmount ? amountSum : null,
    ));
  }
  return result;
}
