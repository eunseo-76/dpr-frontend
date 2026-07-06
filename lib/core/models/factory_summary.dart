class FactorySummary {
  final int factoryId;
  final String factoryName;

  FactorySummary({required this.factoryId, required this.factoryName});

  factory FactorySummary.fromJson(Map<String, dynamic> json) {
    return FactorySummary(
      factoryId: json['factoryId'] as int,
      factoryName: json['factoryName'] as String,
    );
  }

  Map<String, dynamic> toJson() => {
        'factoryId': factoryId,
        'factoryName': factoryName,
      };
}
