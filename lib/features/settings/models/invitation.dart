class Invitation {
  final int invitationId;
  final String email;
  final String role;
  final String? factoryName;
  final String inviteCode;
  final String status;
  final String expiresAt;
  final String createdAt;

  Invitation({
    required this.invitationId,
    required this.email,
    required this.role,
    this.factoryName,
    required this.inviteCode,
    required this.status,
    required this.expiresAt,
    required this.createdAt,
  });

  factory Invitation.fromJson(Map<String, dynamic> json) {
    return Invitation(
      invitationId: json['invitationId'] as int,
      email: json['email'] as String,
      role: json['role'] as String,
      factoryName: json['factoryName'] as String?,
      inviteCode: json['inviteCode'] as String,
      status: json['status'] as String,
      expiresAt: json['expiresAt'] as String,
      createdAt: json['createdAt'] as String,
    );
  }

  bool get isPending => status == 'PENDING';
}
