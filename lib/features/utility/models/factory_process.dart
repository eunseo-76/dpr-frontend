// 공장-공정 매핑 (어떤 공장이 어떤 공정을 사용하는지)
class FactoryProcess {
  final int factoryId;
  final String factoryName;
  final int processId;
  final String processName;
  final String? processNickname;

  FactoryProcess({
    required this.factoryId,
    required this.factoryName,
    required this.processId,
    required this.processName,
    this.processNickname,
  });

  factory FactoryProcess.fromJson(Map<String, dynamic> json) {
    return FactoryProcess(
      factoryId: json['factoryId'] as int,
      factoryName: json['factoryName'] as String,
      processId: json['processId'] as int,
      processName: json['processName'] as String,
      processNickname: json['processNickname'] as String?,
    );
  }
}