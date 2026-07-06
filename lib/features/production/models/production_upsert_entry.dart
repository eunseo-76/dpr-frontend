class ProductionUpsertEntry {
  final int factoryId;
  final int clientId;
  final int processId;
  final int unitId;
  final double? dayShift;
  final double? nightShift;

  ProductionUpsertEntry({
    required this.factoryId,
    required this.clientId,
    required this.processId,
    required this.unitId,
    this.dayShift,
    this.nightShift,
  });

  Map<String, dynamic> toJson() => {
        'factoryId': factoryId,
        'processId': processId,
        'clientId': clientId,
        'unitId': unitId,
        'dayShift': dayShift,
        'nightShift': nightShift,
      };
}