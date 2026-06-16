// 역직렬화
class LoginResponse {
  final String accessToken;
  final String name;
  final String position;
  final String role;
  final int companyId;
  final String companyName;
  final int? factoryId;
  final String? factoryName;

  LoginResponse({
    required this.accessToken,
    required this.name,
    required this.position,
    required this.role,
    required this.companyId,
    required this.companyName,
    this.factoryId,
    this.factoryName,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      role: json['role'] as String,
      companyId: json['companyId'] as int,
      companyName: json['companyName'] as String,
      factoryId: json['factoryId'] as int?,
      factoryName: json['factoryName'] as String?,
    );
  }
}
