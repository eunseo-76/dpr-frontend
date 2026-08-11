import 'dart:convert';

import 'package:fprs_frontend/core/constants/api_constants.dart';
import 'package:fprs_frontend/core/models/factory_summary.dart';
import 'package:fprs_frontend/core/network/api_client.dart';
import 'package:fprs_frontend/core/utils/user_storage.dart';
import 'package:fprs_frontend/features/auth/models/update_user_request.dart';

class UserService {
  final _client = ApiClient();

  Future<void> updateMe(UpdateUserRequest request) async {
    final response = await _client.patch(ApiConstants.updateMe, request.toJson());
    if (response.statusCode != 200) {
      throw Exception('회원정보 수정 실패: ${response.statusCode}');
    }
  }

  // 로그인 시점에 캐싱해둔 role/factories 등이 서버 변경사항(공장 배정 등)을 반영하도록 새로고침
  Future<void> refreshUserInfo() async {
    final response = await _client.get(ApiConstants.updateMe);
    if (response.statusCode != 200) {
      throw Exception('회원정보 조회 실패: ${response.statusCode}');
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final data = body['data'] as Map<String, dynamic>;
    await UserStorage.saveUserInfo(
      data['role'] as String,
      data['name'] as String,
      data['position'] as String,
      data['companyId'] as int,
      data['companyName'] as String,
      (data['factories'] as List? ?? [])
          .map((e) => FactorySummary.fromJson(e as Map<String, dynamic>))
          .toList(),
      nickname: data['nickname'] as String?,
    );
  }
}