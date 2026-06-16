// 전기/용수 입력/수정(upsert) 요청의 entry 한 개
class UtilityUpsertEntry {
  final int factoryId;
  final int processId;
  final double electricity;
  final double water;

  UtilityUpsertEntry({
    required this.factoryId,
    required this.processId,
    required this.electricity,
    required this.water,
  });

  Map<String, dynamic> toJson() => {
        'factoryId': factoryId,
        'processId': processId,
        'electricity': electricity,
        'water': water,
      };
}