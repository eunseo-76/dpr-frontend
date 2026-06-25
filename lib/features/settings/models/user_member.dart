class UserMember {
  final int userId;
  final String name;
  final String email;
  final String position;
  final String role;
  final int? factoryId;
  final String? factoryName;

  UserMember({
    required this.userId,
    required this.name,
    required this.email,
    required this.position,
    required this.role,
    this.factoryId,
    this.factoryName,
  });

  factory UserMember.fromJson(Map<String, dynamic> json) {
    return UserMember(
      userId: json['userId'] as int,
      name: json['name'] as String,
      email: json['email'] as String,
      position: json['position'] as String,
      role: json['role'] as String,
      factoryId: json['factoryId'] as int?,
      factoryName: json['factoryName'] as String?,
    );
  }
}
