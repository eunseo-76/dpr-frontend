class FactoryClient {
  final int factoryId;
  final String factoryName;
  final int clientId;
  final String clientName;

  FactoryClient({
    required this.factoryId,
    required this.factoryName,
    required this.clientId,
    required this.clientName,
  });

  factory FactoryClient.fromJson(Map<String, dynamic> json) {
    return FactoryClient(
      factoryId: json['factoryId'] as int,
      factoryName: json['factoryName'] as String,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
    );
  }
}