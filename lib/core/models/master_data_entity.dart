// 공장, 공정, 단위, 업체가 공통으로 갖는 구조
class MasterDataEntity {
  final int id;
  final String name;

  MasterDataEntity({required this.id, required this.name});

  factory MasterDataEntity.fromJson(Map<String, dynamic> json, String idKey) {
    return MasterDataEntity(
      id: json[idKey] as int,
      name: json['name'] as String,
    );
  }
}