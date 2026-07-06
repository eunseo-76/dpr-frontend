class MasterDataEntity {
  final int id;
  final String name;
  final Map<String, dynamic> data;

  MasterDataEntity({required this.id, required this.name, required this.data});

  factory MasterDataEntity.fromJson(Map<String, dynamic> json, String idKey) {
    return MasterDataEntity(
      id: json[idKey] as int,
      name: json['name'] as String,
      data: json,
    );
  }
}