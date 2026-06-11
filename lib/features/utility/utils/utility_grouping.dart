import 'package:dpr_frontend/features/utility/models/utility.dart';

// UtilityCard의 표 한 줄
// 공장별 뷰 - '공정'
// 공정별 뷰 - '공장'
class UtilityRowData {
  final String label;
  final double electricity;
  final double water;

  UtilityRowData({
    required this.label,
    required this.electricity,
    required this.water,
  });
}

// UtilityCard 한 장
// 공장별 뷰 - '공장'
// 공정별 뷰 - '공정'
class UtilityGroup {
  final int groupId;
  final String groupName;
  final List<UtilityRowData> rows;

  UtilityGroup({
    required this.groupId,
    required this.groupName,
    required this.rows,
  });
}

// List<Utility> 를 List<UtilityGroup> 카드로
List<UtilityGroup> groupUtilities(List<Utility> utilities, String groupBy) {
  final Map<int, String> groupNames = {}; // groupId -> 카드 제목
  final Map<int, List<UtilityRowData>> groupRows = {}; // groupId -> 행 목록

  for (final u in utilities) {
    late final int groupId;
    late final String groupName;
    late final String rowLabel;

    // groupBy에 따라 groupId / groupName / rowLabel 결정
    if (groupBy == '공장별') {
      groupId = u.factoryId;
      groupName = u.factoryName;  // 카드는 공장
      rowLabel = u.processName; // 행은 공정
    } else {
      groupId = u.processId;
      groupName = u.processName;  // 카드는 공정
      rowLabel = u.factoryName; // 행은 공장
    }

    groupNames.putIfAbsent(groupId, () => groupName); // groupId를 카드 제목으로 (같은 groupId는 무시)
    groupRows.putIfAbsent(groupId, () => []);
    groupRows[groupId]!.add(UtilityRowData(
      label: rowLabel,
      electricity: u.electricity ?? 0,
      water: u.water ?? 0,
    ));
  }

  // [UtilityGroup(1,"공장A",[3개행]), UtilityGroup(2,"공장B",[2개행])]
  return groupNames.entries
      .map((e) => UtilityGroup(
            groupId: e.key,
            groupName: e.value,
            rows: groupRows[e.key]!,
          ))
      .toList();
}