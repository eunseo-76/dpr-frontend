class FactoryClient {
  final int factoryId;
  final String factoryName;
  final int clientId;
  final String clientName;
  final String? clientNickname;

  FactoryClient({
    required this.factoryId,
    required this.factoryName,
    required this.clientId,
    required this.clientName,
    this.clientNickname,
  });

  factory FactoryClient.fromJson(Map<String, dynamic> json) {
    return FactoryClient(
      factoryId: json['factoryId'] as int,
      factoryName: json['factoryName'] as String,
      clientId: json['clientId'] as int,
      clientName: json['clientName'] as String,
      clientNickname: json['clientNickname'] as String?,
    );
  }
}