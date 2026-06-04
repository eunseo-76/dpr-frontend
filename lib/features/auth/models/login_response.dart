// 역직렬화
class LoginResponse {
  final String accessToken;
  final String name;
  final String position;
  final String role;
  final int companyId;
  final int? factoryId; // OWNER는 nullable

  LoginResponse({
    required this.accessToken,
    required this.name,
    required this.position,
    required this.role,
    required this.companyId,
    this.factoryId,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      name: json['name'] as String,
      position: json['position'] as String,
      role: json['role'] as String,
      companyId: json['companyId'] as int,
      factoryId: json['factoryId'] as int?,
    );
  }
}
