class UtilitySummary {
  final int groupId;
  final String groupName;
  final double? electricitySum;
  final double? waterSum;

  UtilitySummary({
    required this.groupId,
    required this.groupName,
    required this.electricitySum,
    required this.waterSum,
  });

  factory UtilitySummary.fromJson(Map<String, dynamic> json) {
    return UtilitySummary(
      groupId: json['groupId'] as int,
      groupName: json['groupName'] as String,
      electricitySum: (json['electricitySum'] as num?)?.toDouble(),
      waterSum: (json['waterSum'] as num?)?.toDouble(),
    );
  }
}