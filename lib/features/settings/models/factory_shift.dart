class FactoryShift {
  final bool hasNightShift;
  final String dayShiftStart;
  final String dayShiftEnd;
  final String? nightShiftStart;
  final String? nightShiftEnd;

  FactoryShift({
    required this.hasNightShift,
    required this.dayShiftStart,
    required this.dayShiftEnd,
    this.nightShiftStart,
    this.nightShiftEnd,
  });

  factory FactoryShift.fromJson(Map<String, dynamic> json) {
    return FactoryShift(
      hasNightShift: json['hasNightShift'] as bool? ?? false,
      dayShiftStart: json['dayShiftStart'] as String,
      dayShiftEnd: json['dayShiftEnd'] as String,
      nightShiftStart: json['nightShiftStart'] as String?,
      nightShiftEnd: json['nightShiftEnd'] as String?,
    );
  }
}