import 'package:dpr_frontend/features/utility/models/utility.dart';

// 주/월/년 보기

// UtilityCard의 표 한 줄
// label: 공장별 뷰 - '공정' , 공정별 뷰 - '공장'
// values: dateColumns 순서에 맞춘 기간별 값 (e.g. 월~일 7개). null = 해당 날짜 데이터 없음
// total: values의 합계 (null은 0으로 취급)
class UtilityPeriodRowData {
  final String label;
  final List<double?> values;
  final double total;

  UtilityPeriodRowData({
    required this.label,
    required this.values,
    required this.total,
  });
}

// 주/월/년 보기의 카드 한 장
// 공장별 뷰 - '공장' / 공정별 뷰 - '공정'
// "구분"(전기/용수)으로 행이 나뉘므로 두 개의 row 리스트
class UtilityPeriodGroup {
  final int groupId;
  final String groupName;
  final List<UtilityPeriodRowData> electricityRows;
  final List<UtilityPeriodRowData> waterRows;

  UtilityPeriodGroup({
    required this.groupId,
    required this.groupName,
    required this.electricityRows,
    required this.waterRows,
  });
}

// List<Utility> 를 dateColumns 기준으로 피벗하여
// List<UtilityPeriodGroup>으로 변환
List<UtilityPeriodGroup> groupUtilitiesByPeriod(
  List<Utility> utilities,
  String groupBy,
  List<String> dateColumns,
) {
  final Map<int, String> groupNames = {}; // groupId -> 카드 제목
  final Map<int, List<String>> rowLabelsByGroup = {}; // groupId -> 행 라벨 순서
  final Map<String, Map<String, Utility>> recordsByKey = {}; // '$groupId|$rowLabel' -> {date: Utility}

  for (final u in utilities) {
    late final int groupId;
    late final String groupName;
    late final String rowLabel;

    // groupBy에 따라 groupId / groupName / rowLabel 결정 (groupUtilities와 동일)
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

      final electricityValues =
          dateColumns.map((date) => records[date]?.electricity).toList();
      final waterValues =
          dateColumns.map((date) => records[date]?.water).toList();

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