import 'package:fprs_frontend/features/production/models/production.dart';
import 'package:fprs_frontend/features/utility/models/factory_process.dart';

class PeriodDailyRow {
  final int processId;
  final String processName;
  final String shift; // '주' | '야'
  final String itemLabel; // '실적' | '재공' | '금액'
  final double? average; // 재공 모드에서만 채움
  final List<double?> values; // 날짜별 값, dates와 같은 길이
  final double? total; // 실적 모드에서만 채움

  PeriodDailyRow({
    required this.processId,
    required this.processName,
    required this.shift,
    required this.itemLabel,
    this.average,
    required this.values,
    this.total,
  });
}

List<PeriodDailyRow> groupProductionsForPeriodDaily(
  List<Production> productions,
  List<FactoryProcess> factoryProcesses,
  List<String> dates, {
  required bool hasNightShift,
  required bool showWip,
}) {
  final processNicknames = <int, String>{};
  for (final p in productions) {
    if (p.processNickname != null) processNicknames[p.processId] = p.processNickname!;
  }

  // productions는 이미 업체/단위로 서버 필터된 상태라 (날짜, 공정) 조합당 최대 1행
  final byDateAndProcess = <String, Production>{
    for (final p in productions) '${p.date}|${p.processId}': p,
  };

  double? averageOf(List<double?> values) {
    final present = values.whereType<double>().toList();
    if (present.isEmpty) return null;
    return present.reduce((a, b) => a + b) / present.length;
  }

  double? sumOf(List<double?> values) {
    final present = values.whereType<double>().toList();
    if (present.isEmpty) return null;
    return present.reduce((a, b) => a + b);
  }

  final rows = <PeriodDailyRow>[];

  for (final process in factoryProcesses) {
    final processName = processNicknames[process.processId] ??
        process.processNickname ??
        process.processName;

    for (final shift in hasNightShift ? ['주', '야'] : ['주']) {
      final quantities = dates.map((date) {
        final p = byDateAndProcess['$date|${process.processId}'];
        if (p == null) return null;
        return showWip
            ? (shift == '주' ? p.wipDayShift : p.wipNightShift)
            : (shift == '주' ? p.dayShift : p.nightShift);
      }).toList();

      // 기간 전체에서 이 (공정, 구분) 조합에 데이터가 하나도 없으면 행 자체를 안 만듦
      // (다른 화면들과 동일한 제로 스킵 원칙)
      if (quantities.every((v) => v == null || v == 0)) continue;

      final amounts = List.generate(dates.length, (i) {
        final p = byDateAndProcess['${dates[i]}|${process.processId}'];
        final qty = quantities[i];
        if (p?.unitPrice == null || qty == null) return null;
        return qty * p!.unitPrice!;
      });

      rows.add(PeriodDailyRow(
        processId: process.processId,
        processName: processName,
        shift: shift,
        itemLabel: showWip ? '재공' : '실적',
        average: showWip ? averageOf(quantities) : null,
        values: quantities,
        total: showWip ? null : sumOf(quantities),
      ));

      rows.add(PeriodDailyRow(
        processId: process.processId,
        processName: processName,
        shift: shift,
        itemLabel: '금액',
        average: showWip ? averageOf(amounts) : null,
        values: amounts,
        total: showWip ? null : sumOf(amounts),
      ));
    }
  }

  return rows;
}
