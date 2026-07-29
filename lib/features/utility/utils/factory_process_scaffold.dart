import 'package:fprs_frontend/features/utility/models/factory_process.dart';

// 카드 안의 한 행 - (factoryId, processId)가 실적 데이터를 찾는 key가 된다
// 공장별 뷰 -> label은 공정명, 공정별 뷰 -> label은 공장명
class RowScaffold {
  final int factoryId;
  final int processId;
  final String label;

  RowScaffold({
    required this.factoryId,
    required this.processId,
    required this.label,
  });
}

// 카드 한 장의 뼈대 - 카드 제목 + 카드 안에 들어갈 행 목록
// 공장별 뷰 -> 카드 = 공장, 공정별 뷰 -> 카드 = 공정
class GroupScaffold {
  final int groupId;
  final String groupName;
  final List<RowScaffold> rows;

  GroupScaffold({
    required this.groupId,
    required this.groupName,
    required this.rows,
  });
}

// factoryProcesses(공장-공정 매핑)로부터 카드+행 뼈대를 만든다.
// 실적 데이터(utilities)에 없는 (공장,공정) 조합도 전부 행으로 포함된다.
List<GroupScaffold> buildScaffold(
  List<FactoryProcess> factoryProcesses,
  String groupBy,
) {
  final Map<int, String> groupNames = {}; // groupId -> 카드 제목
  final Map<int, List<RowScaffold>> groupRows = {}; // groupId -> 행 목록

  for (final fp in factoryProcesses) {
    late final int groupId;
    late final String groupName;
    late final String rowLabel;

    if (groupBy == '공장별') {
      groupId = fp.factoryId;
      groupName = fp.factoryName;
      rowLabel = fp.processName;
    } else {
      groupId = fp.processId;
      groupName = fp.processName;
      rowLabel = fp.factoryName;
    }

    groupNames.putIfAbsent(groupId, () => groupName);
    groupRows.putIfAbsent(groupId, () => []).add(RowScaffold(
          factoryId: fp.factoryId,
          processId: fp.processId,
          label: rowLabel,
        ));
  }

  return groupNames.entries
      .map((e) => GroupScaffold(
            groupId: e.key,
            groupName: e.value,
            rows: groupRows[e.key]!,
          ))
      .toList();
}