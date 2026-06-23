class UnitPrice {
  final int clientId;
  final String clientName;
  final int unitId;
  final String unitName;
  final double price;

  UnitPrice({
    required this.clientId,
    required this.clientName,
    required this.unitId,
    required this.unitName,
    required this.price,
  });

  factory UnitPrice.fromJson(Map<String, dynamic> json) {
    return UnitPrice(
        clientId: json['clientId'] as int,
        clientName: json['clientName'] as String,
        unitId: json['unitId'] as int,
        unitName: json['unitName'] as String,
        price: (json['price'] as num).toDouble()
    );
  }
}