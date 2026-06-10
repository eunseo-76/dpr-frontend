class Utility {
  final int utilityId;
  final String date;
  final int factoryId;
  final String factoryName;
  final int processId;
  final String processName;
  final double? electricity;
  final double? water;
  final String status;

  Utility({
    required this.utilityId,
    required this.date,
    required this.factoryId,
    required this.factoryName,
    required this.processId,
    required this.processName,
    required this.electricity,
    required this.water,
    required this.status,
  });

  factory Utility.fromJson(Map<String, dynamic> json) {
    return Utility(
        utilityId: json['utilityId'] as int,
        date: json['date'] as String,
        factoryId: json['factoryId'] as int,
        factoryName: json['factoryName'] as String,
        processId: json['processId'] as int,
        processName: json['processName'] as String,
        electricity: (json['electricity'] as num?)?.toDouble(),
        water: (json['water'] as num?)?.toDouble(),
        status: json['status'] as String,
    );

  }
}