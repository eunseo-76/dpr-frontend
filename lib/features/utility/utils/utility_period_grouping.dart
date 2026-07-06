import 'package:dpr_frontend/features/utility/models/utility.dart';
import 'package:dpr_frontend/features/utility/utils/factory_process_scaffold.dart';

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

// scaffold(공장-공정 매핑으로 만든 카드+행 뼈대)를 dateColumns 기준으로 피벗하여
// List<UtilityPeriodGroup>으로 변환. utilities는 (factoryId, processId, date) -> Utility
// 조회용 데이터로만 사용한다.
List<UtilityPeriodGroup> groupUtilitiesByPeriod(
  List<Utility> utilities,
  List<GroupScaffold> scaffold,
  List<String> dateColumns,
) {
  final Map<String, Utility> byKey = {
    for (final u in utilities) '${u.factoryId}|${u.processId}|${u.date}': u,
  };

  return scaffold.map((group) {
    final electricityRows = <UtilityPeriodRowData>[];
    final waterRows = <UtilityPeriodRowData>[];

    for (final row in group.rows) {
      final electricityValues = dateColumns
          .map((date) =>
              byKey['${row.factoryId}|${row.processId}|$date']?.electricity)
          .toList();
      final waterValues = dateColumns
          .map((date) =>
              byKey['${row.factoryId}|${row.processId}|$date']?.water)
          .toList();

      electricityRows.add(UtilityPeriodRowData(
        label: row.label,
        values: electricityValues,
        total: electricityValues.fold(0.0, (a, b) => a + (b ?? 0.0)),
      ));
      waterRows.add(UtilityPeriodRowData(
        label: row.label,
        values: waterValues,
        total: waterValues.fold(0.0, (a, b) => a + (b ?? 0.0)),
      ));
    }

    return UtilityPeriodGroup(
      groupId: group.groupId,
      groupName: group.groupName,
      electricityRows: electricityRows,
      waterRows: waterRows,
    );
  }).toList();
}