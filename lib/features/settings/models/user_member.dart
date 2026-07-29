import 'package:fprs_frontend/core/models/factory_summary.dart';

class UserMember {
  final int userId;
  final String name;
  final String email;
  final String position;
  final String role;
  final List<FactorySummary> factories;

  UserMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.position,
    required this.role,
    required this.factories,
  });

  factory UserMember.fromJson(Map<String, dynamic> json) {
    return UserMember(
      userId: json['userId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      position: json['position'] as String,
      role: json['role'] as String,
      factories: (json['factories'] as List? ?? [])
          .map((e) => FactorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}
