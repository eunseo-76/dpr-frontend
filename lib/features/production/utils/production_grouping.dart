import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/utils/production_scaffold.dart';

class ProductionDayRow {
  final int rowGroupId;
  final String rowGroupName;
  final String shift;
  final int unitId;
  final String unitName;
  final double? value;
  final double? wip;
  final double? unitPrice;
  final int? productionId;

  final double? amount;
  final double? monthlyCumulativeResult;
  final double? monthlyCumulativeAmount;

  ProductionDayRow({
    required this.rowGroupId,
    required this.rowGroupName,
    required this.shift,
    required this.unitId,
    required this.unitName,
    this.value,
    this.wip,
    this.unitPrice,
    this.amount,
    this.monthlyCumulativeResult,
    this.monthlyCumulativeAmount,
    this.productionId,
  });
}

class ProductionDayGroup {
  final int groupId;
  final String groupName;
  final List<ProductionDayRow> rows;
  final Map<int, double> dailySumByUnit;
  final Map<int, double> cumulativeSumByUnit;
  final Map<int, double> amountByUnit;
  final Map<int, double> cumulativeAmountByUnit;

  ProductionDayGroup({
    required this.groupId,
    required this.groupName,
    required this.rows,
    required this.dailySumByUnit,
    required this.cumulativeSumByUnit,
    required this.amountByUnit,
    required this.cumulativeAmountByUnit,
  });
}

List<ProductionDayGroup> groupProductionsForDay(
  List<Production> productions,
  List<ProductionGroupScaffold> scaffold,
  String groupBy, {
  required bool showAmount,
}) {
  final processNicknames = <int, String>{};
  final clientNicknames = <int, String>{};
  for (final p in productions) {
    if (p.processNickname != null) processNicknames[p.processId] = p.processNickname!;
    if (p.clientNickname != null) clientNicknames[p.clientId] = p.clientNickname!;
  }

  return scaffold.map((group) {
    final cardProductions = productions.where((p) =>
      groupBy == '공정별'
          ? p.processId == group.groupId
          : p.clientId == group.groupId
    ).toList();

    final groupNickname = groupBy == '공정별'
        ? processNicknames[group.groupId]
        : clientNicknames[group.groupId];

    final unitRows = group.rows.map((rowScaffold) {
      final matches = cardProductions.where((p) =>
        (groupBy == '공정별' ? p.clientId : p.processId) == rowScaffold.rowGroupId &&
        p.unitId == rowScaffold.unitId
      );
      final production = matches.isEmpty ? null : matches.first;

      final rowNickname = groupBy == '공정별'
          ? clientNicknames[rowScaffold.rowGroupId]
          : processNicknames[rowScaffold.rowGroupId];

      final value = rowScaffold.shift == '주'
          ? production?.dayShift
          : production?.nightShift;
      final wip = rowScaffold.shift == '주'
          ? production?.wipDayShift
          : production?.wipNightShift;

      final monthlyCumulativeResult = rowScaffold.shift == '주'
          ? production?.dayMonthlyCumulativeResult
          : production?.nightMonthlyCumulativeResult;
      final monthlyCumulativeAmount = rowScaffold.shift == '주'
          ? production?.dayMonthlyCumulativeAmount
          : production?.nightMonthlyCumulativeAmount;

      return ProductionDayRow(
        rowGroupId: rowScaffold.rowGroupId,
        rowGroupName: rowNickname ?? rowScaffold.rowGroupName,
        shift: rowScaffold.shift,
        unitId: rowScaffold.unitId,
        unitName: rowScaffold.unitName,
        value: value,
        wip: wip,
        unitPrice: production?.unitPrice,
        amount: (value != null && production?.unitPrice != null)
            ? value * production!.unitPrice!
            : null,
        monthlyCumulativeResult: monthlyCumulativeResult,
        monthlyCumulativeAmount: monthlyCumulativeAmount,
        productionId: production?.productionId,
      );
    }).toList();

    final rows = _injectAmountRows(unitRows, showAmount: showAmount);

    final dailySums = <int, double>{};
    final cumulativeSums = <int, double>{};
    final amountSums = <int, double>{};
    final cumulativeAmountSums = <int, double>{};
    for (final p in cardProductions) {
      dailySums[p.unitId] = (dailySums[p.unitId] ?? 0) + (p.result ?? 0);
      cumulativeSums[p.unitId] = (cumulativeSums[p.unitId] ?? 0) +
          (p.dayMonthlyCumulativeResult ?? 0) +
          (p.nightMonthlyCumulativeResult ?? 0);
      if (p.amount != null) {
        amountSums[p.unitId] = (amountSums[p.unitId] ?? 0) + p.amount!;
      }
      if (p.dayMonthlyCumulativeAmount != null || p.nightMonthlyCumulativeAmount != null) {
        cumulativeAmountSums[p.unitId] = (cumulativeAmountSums[p.unitId] ?? 0) +
            (p.dayMonthlyCumulativeAmount ?? 0) +
            (p.nightMonthlyCumulativeAmount ?? 0);
      }
    }

    return ProductionDayGroup(
      groupId: group.groupId,
      groupName: groupNickname ?? group.groupName,
      rows: rows,
      dailySumByUnit: dailySums,
      cumulativeSumByUnit: cumulativeSums,
      amountByUnit: amountSums,
      cumulativeAmountByUnit: cumulativeAmountSums,
    );
  }).toList();
}

List<ProductionDayRow> _injectAmountRows(
  List<ProductionDayRow> unitRows, {
  required bool showAmount,
}) {
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
    if (!showAmount) continue;

    double amountSum = 0;
    bool hasAmount = false;
    double wipAmountSum = 0;
    bool hasWipAmount = false;
    double monthlyCumulativeAmountSum = 0;
    bool hasMonthlyCumulativeAmount = false;
    for (final r in shiftRows) {
      if (r.amount != null) {
        amountSum += r.amount!;
        hasAmount = true;
      }
      if (r.wip != null && r.unitPrice != null) {
        wipAmountSum += r.wip! * r.unitPrice!;
        hasWipAmount = true;
      }
      if (r.monthlyCumulativeAmount != null) {
        monthlyCumulativeAmountSum += r.monthlyCumulativeAmount!;
        hasMonthlyCumulativeAmount = true;
      }
    }

    result.add(ProductionDayRow(
      rowGroupId: groupId,
      rowGroupName: shiftRows.first.rowGroupName,
      shift: shift,
      unitId: -1,
      unitName: '금액',
      value: hasAmount ? amountSum : null,
      wip: hasWipAmount ? wipAmountSum : null,
      monthlyCumulativeAmount: hasMonthlyCumulativeAmount ? monthlyCumulativeAmountSum : null,
    ));
  }
  return result;
}
