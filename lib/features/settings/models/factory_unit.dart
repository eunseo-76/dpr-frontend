class FactoryUnit {
  final int factoryId;
  final String factoryName;
  final int unitId;
  final String unitName;
  final String? unitNickname;

  FactoryUnit({
    required this.factoryId,
    required this.factoryName,
    required this.unitId,
    required this.unitName,
    this.unitNickname,
  });

  factory FactoryUnit.fromJson(Map<String, dynamic> json) {
    return FactoryUnit(
      factoryId: json['factoryId'] as int,
      factoryName: json['factoryName'] as String,
      unitId: json['unitId'] as int,
      unitName: json['unitName'] as String,
      unitNickname: json['unitNickname'] as String?,
    );
  }
}