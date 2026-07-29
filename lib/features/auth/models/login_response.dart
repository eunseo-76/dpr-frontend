import 'package:fprs_frontend/core/models/factory_summary.dart';

// 역직렬화
class LoginResponse {
  final String accessToken;
  final String name;
  final String? nickname;
  final String position;
  final String role;
  final int companyId;
  final String companyName;
  final List<FactorySummary> factories;

  LoginResponse({
    required this.accessToken,
    required this.name,
    this.nickname,
    required this.position,
    required this.role,
    required this.companyId,
    required this.companyName,
    required this.factories,
  });

  factory LoginResponse.fromJson(Map<String, dynamic> json) {
    return LoginResponse(
      accessToken: json['accessToken'] as String,
      name: json['name'] as String,
      nickname: json['nickname'] as String?,
      position: json['position'] as String,
      role: json['role'] as String,
      companyId: json['companyId'] as int,
      companyName: json['companyName'] as String,
      factories: (json['factories'] as List? ?? [])
          .map((e) => FactorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
