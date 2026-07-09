class Production {
  final int productionId;
  final String date;
  final int companyId;
  final int factoryId;
  final int processId;
  final String processName;
  final String? processNickname;
  final int clientId;
  final String clientName;
  final String? clientNickname;
  final int unitId;
  final String unitName;
  final double? dayShift;
  final double? nightShift;
  final double? wipDayShift;
  final double? wipNightShift;
  final double? result;
  final double? wipResult;
  final double? cumulativeResult;
  final double? monthlyCumulativeResult;
  final double? monthlyCumulativeAmount;
  final double? unitPrice;
  final double? amount;
  final double? wipAmount;
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
    this.processNickname,
    required this.clientId,
    required this.clientName,
    this.clientNickname,
    required this.unitId,
    required this.unitName,
    this.dayShift,
    this.nightShift,
    this.wipDayShift,
    this.wipNightShift,
    this.result,
    this.wipResult,
    this.cumulativeResult,
    this.monthlyCumulativeResult,
    this.monthlyCumulativeAmount,
    this.unitPrice,
    this.amount,
    this.wipAmount,
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
      processNickname: json['processNickname'] as String?,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      clientNickname: json['clientNickname'] as String?,
      unitId: json['unitId'] as int,
      unitName: json['unitName'] as String,
      dayShift: (json['dayShift'] as num?)?.toDouble(),
      nightShift: (json['nightShift'] as num?)?.toDouble(),
      wipDayShift: (json['wipDayShift'] as num?)?.toDouble(),
      wipNightShift: (json['wipNightShift'] as num?)?.toDouble(),
      result: (json['result'] as num?)?.toDouble(),
      wipResult: (json['wipResult'] as num?)?.toDouble(),
      cumulativeResult: (json['cumulativeResult'] as num?)?.toDouble(),
      monthlyCumulativeResult: (json['monthlyCumulativeResult'] as num?)?.toDouble(),
      monthlyCumulativeAmount: (json['monthlyCumulativeAmount'] as num?)?.toDouble(),
      unitPrice: (json['unitPrice'] as num?)?.toDouble(),
      amount: (json['amount'] as num?)?.toDouble(),
      wipAmount: (json['wipAmount'] as num?)?.toDouble(),
      createdName: json['createdName'] as String,
      updatedAt: json['updatedAt'] as String?,
      status: json['status'] as String,
    );
  }
}