import 'package:dpr_frontend/features/utility/models/utility.dart';
import 'package:dpr_frontend/features/utility/utils/factory_process_scaffold.dart';

// 일별 보기

// UtilityCard의 표 한 줄
// 공장별 뷰 - '공정'
// 공정별 뷰 - '공장'
// electricity/water: null = 미입력 ("-"로 표시)
class UtilityRowData {
  final String label;
  final double? electricity;
  final double? water;

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

// scaffold(공장-공정 매핑으로 만든 카드+행 뼈대)를 기준으로 List<UtilityGroup> 카드를 만든다.
// utilities는 (factoryId, processId) -> Utility 조회용 데이터로만 사용한다.
// scaffold에는 있지만 utilities에 없는 행은 electricity/water가 null("-")로 표시된다.
List<UtilityGroup> groupUtilities(
  List<Utility> utilities,
  List<GroupScaffold> scaffold,
) {
  final Map<String, Utility> byKey = {
    for (final u in utilities) '${u.factoryId}|${u.processId}': u,
  };

  return scaffold
      .map((group) => UtilityGroup(
            groupId: group.groupId,
            groupName: group.groupName,
            rows: group.rows
                .map((row) {
                  final u = byKey['${row.factoryId}|${row.processId}'];
                  return UtilityRowData(
                    label: row.label,
                    electricity: u?.electricity,
                    water: u?.water,
                  );
                })
                .toList(),
          ))
      .toList();
}