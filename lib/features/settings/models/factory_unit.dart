class FactoryUnit {
  final int factoryId;
  final String factoryName;
  final int unitId;
  final String unitName;

  FactoryUnit({
    required this.factoryId,
    required this.factoryName,
    required this.unitId,
    required this.unitName,
  });

  factory FactoryUnit.fromJson(Map<String, dynamic> json) {
    return FactoryUnit(
      factoryId: json['factoryId'] as int,
      factoryName: json['factoryName'] as String,
      unitId: json['unitId'] as int,
      unitName: json['unitName'] as String,
    );
  }
}