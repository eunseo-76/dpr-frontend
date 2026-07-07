class ProcessUnitPrice {
  final int processId;
  final String processName;
  final int unitId;
  final String unitName;
  final double price;

  ProcessUnitPrice({
    required this.processId,
    required this.processName,
    required this.unitId,
    required this.unitName,
    required this.price,
  });

  factory ProcessUnitPrice.fromJson(Map<String, dynamic> json) {
    return ProcessUnitPrice(
        processId: json['processId'] as int,
        processName: json['processName'] as String,
        unitId: json['unitId'] as int,
        unitName: json['unitName'] as String,
        price: (json['price'] as num).toDouble()
    );
  }
}
