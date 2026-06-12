import 'package:dpr_frontend/features/utility/models/utility.dart';
import 'package:dpr_frontend/features/utility/utils/utility_period_grouping.dart';

// 주/월/년 보기에서 표의 한 열(컬럼)
// label: 헤더에 표시할 기간 ('08', '5/4~5/10', '1월' 등)
// dates: 이 컬럼에 합산될 날짜들 ('yyyy-MM-dd')
class PeriodColumn {
  final String label;
  final List<String> dates;

  PeriodColumn({required this.label, required this.dates});
}

// year/month의 1일~말일을 주(월~일) 단위로 묶어 4~5개 컬럼 생성
// 첫 주/마지막 주는 이번 달에 속한 날짜만 담겨 7개보다 적을 수도
List<PeriodColumn> monthPeriodColumns(int year, int month) {
  final lastDay = DateTime(year, month + 1, 0).day;
  final columns = <PeriodColumn>[];

  for (int day = 1; day <= lastDay; day++) {
    final date = DateTime(year, month, day);
    final monday = date.subtract(Duration(days: date.weekday - 1));
    final sunday = monday.add(const Duration(days: 6));
    final label =
        '${monday.month}/${monday.day}~${sunday.month}/${sunday.day}';
    final dateStr = date.toIso8601String().substring(0, 10);

    if (columns.isNotEmpty && columns.last.label == label) {
      columns.last.dates.add(dateStr);
    } else {
      columns.add(PeriodColumn(label: label, dates: [dateStr]));
    }
  }

  return columns;
}

// year의 1월~12월을 월 단위로 묶어 12개 컬럼 생성 (각 컬럼 = 그 달의 1일~말일 전체)
List<PeriodColumn> yearPeriodColumns(int year) {
  return List.generate(12, (i) {
    final month = i + 1;
    final lastDay = DateTime(year, month + 1, 0).day;
    final dates = List.generate(
      lastDay,
      (d) => DateTime(year, month, d + 1).toIso8601String().substring(0, 10),
    );
    return PeriodColumn(label: '$month월', dates: dates);
  });
}

// utilities를 columns 기준으로 피벗 + 합산
// 출력 모양은 groupUtilitiesByPeriod와 동일 (UtilityPeriodGroup/UtilityPeriodRowData 재사용)
List<UtilityPeriodGroup> groupUtilitiesByColumns(
  List<Utility> utilities,
  String groupBy,
  List<PeriodColumn> columns,
) {
  final Map<int, String> groupNames = {}; // groupId -> 카드 제목
  final Map<int, List<String>> rowLabelsByGroup = {}; // groupId -> 행 라벨 순서
  final Map<String, Map<String, Utility>> recordsByKey = {}; // '$groupId|$rowLabel' -> {date: Utility}

  for (final u in utilities) {
    late final int groupId;
    late final String groupName;
    late final String rowLabel;

    // groupBy에 따라 groupId / groupName / rowLabel 결정 (groupUtilitiesByPeriod와 동일)
    if (groupBy == '공장별') {
      groupId = u.factoryId;
      groupName = u.factoryName;
      rowLabel = u.processName;
    } else {
      groupId = u.processId;
      groupName = u.processName;
      rowLabel = u.factoryName;
    }

    groupNames.putIfAbsent(groupId, () => groupName);

    final labels = rowLabelsByGroup.putIfAbsent(groupId, () => []);
    if (!labels.contains(rowLabel)) labels.add(rowLabel);

    final key = '$groupId|$rowLabel';
    recordsByKey.putIfAbsent(key, () => {})[u.date] = u;
  }

  final groups = <UtilityPeriodGroup>[];

  for (final entry in groupNames.entries) {
    final groupId = entry.key;
    final groupName = entry.value;

    final electricityRows = <UtilityPeriodRowData>[];
    final waterRows = <UtilityPeriodRowData>[];

    for (final rowLabel in rowLabelsByGroup[groupId]!) {
      final records = recordsByKey['$groupId|$rowLabel']!;

      // 컬럼별로 그 안의 날짜들을 합산. 전부 레코드 없으면 null, 하나라도 있으면 합산
      final electricityValues = columns
          .map((column) => _sumOrNull(
                column.dates.map((date) => records[date]?.electricity),
              ))
          .toList();
      final waterValues = columns
          .map((column) => _sumOrNull(
                column.dates.map((date) => records[date]?.water),
              ))
          .toList();

      electricityRows.add(UtilityPeriodRowData(
        label: rowLabel,
        values: electricityValues,
        total: electricityValues.fold(0.0, (a, b) => a + (b ?? 0.0)),
      ));
      waterRows.add(UtilityPeriodRowData(
        label: rowLabel,
        values: waterValues,
        total: waterValues.fold(0.0, (a, b) => a + (b ?? 0.0)),
      ));
    }

    groups.add(UtilityPeriodGroup(
      groupId: groupId,
      groupName: groupName,
      electricityRows: electricityRows,
      waterRows: waterRows,
    ));
  }

  return groups;
}

// 모든 값이 null이면 null, 하나라도 있으면 null을 0으로 취급해 합산
double? _sumOrNull(Iterable<double?> values) {
  if (values.every((v) => v == null)) return null;
  return values.fold<double>(0.0, (a, b) => a + (b ?? 0.0));
}