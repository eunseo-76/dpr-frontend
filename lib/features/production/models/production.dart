class Production {
  final int productionId;
  final String date;
  final int companyId;
  final int factoryId;
  final int processId;
  final String processName;
  final int clientId;
  final String clientName;
  final int unitId;
  final String unitName;
  final double? dayShift;
  final double? nightShift;
  final double? result;
  final double? cumulativeResult;
  final double? unitPrice;
  final String createdName;
  final String? updatedAt;
  final String status;

  Production({
    required this.productionId,
    required this.date,
    required this.companyId,
    required this.factoryId,
    required this.processId,
    required this.processName,
    required this.clientId,
    required this.clientName,
    required this.unitId,
    required this.unitName,
    this.dayShift,
    this.nightShift,
    this.result,
    this.cumulativeResult,
    this.unitPrice,
    required this.createdName,
    this.updatedAt,
    required this.status,
  });

  factory Production.fromJson(Map<String, dynamic> json) {
    return Production(
      productionId: json['productionId'] as int,
      date: json['date'] as String,
      companyId: json['companyId'] as int,
      factoryId: json['factoryId'] as int,
      processId: json['processId'] as int,
      processName: json['processName'] as String,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      unitId: json['unitId'] as int,
      unitName: json['unitName'] as String,
      dayShift: (json['dayShift'] as num?)?.toDouble(),
      nightShift: (json['nightShift'] as num?)?.toDouble(),
      result: (json['result'] as num?)?.toDouble(),
      cumulativeResult: (json['cumulativeResult'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      createdName: json['createdName'] as String,
      updatedAt: json['updatedAt'] as String?,
      status: json['status'] as String,
    );
  }
}
