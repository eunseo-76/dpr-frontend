class UpdateUserRequest {
  final String name;
  final String? nickname;

  UpdateUserRequest({required this.name, this.nickname});

  Map<String, dynamic> toJson() => {
        'name': name,
        if (nickname != null && nickname!.isNotEmpty) 'nickname': nickname,
      };
}