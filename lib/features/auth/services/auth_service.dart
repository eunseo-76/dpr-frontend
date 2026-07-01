import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/core/utils/token_storage.dart';
import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/features/auth/models/login_request.dart';
import 'package:dpr_frontend/features/auth/models/login_response.dart';

class AuthService {
  final _client = ApiClient();

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _client.post(ApiConstants.login, request.toJson());

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final loginResponse = LoginResponse.fromJson(
        body['data'] as Map<String, dynamic>,
      );
      await TokenStorage.saveToken(loginResponse.accessToken);
      await UserStorage.saveUserInfo(
        loginResponse.role,
        loginResponse.name,
        loginResponse.position,
        loginResponse.companyId,
        loginResponse.companyName,
        loginResponse.factoryId,
        loginResponse.factoryName,
      );
      return loginResponse;
    }
    throw Exception(body['message'] as String? ?? '로그인에 실패했습니다');
  }

  Future<Map<String, dynamic>> verifyInviteCode(String code) async {
    final response = await _client.get(
      ApiConstants.invite,
      queryParams: {'code': code},
    );

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      return body['data'] as Map<String, dynamic>;
    }
    throw Exception(body['message'] as String? ?? '초대코드 확인에 실패했습니다');
  }

  Future<LoginResponse> register({
    required String inviteCode,
    required String name,
    required String nickname,
    required String password,
  }) async {
    final response = await _client.post(ApiConstants.register, {
      'inviteCode': inviteCode,
      'name': name,
      'nickname': nickname,
      'password': password,
    });

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      final loginResponse = LoginResponse.fromJson(
        body['data'] as Map<String, dynamic>,
      );
      await TokenStorage.saveToken(loginResponse.accessToken);
      await UserStorage.saveUserInfo(
        loginResponse.role,
        loginResponse.name,
        loginResponse.position,
        loginResponse.companyId,
        loginResponse.companyName,
        loginResponse.factoryId,
        loginResponse.factoryName,
      );
      return loginResponse;
    }
    throw Exception(body['message'] as String? ?? '회원가입에 실패했습니다');
  }

  Future<void> withdraw(String password) async {
    final response = await _client.delete(
      ApiConstants.updateMe,
      {'password': password},
    );

    if (response.statusCode == 200) return;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['message'] as String? ?? '탈퇴에 실패했습니다');
  }

  Future<void> forgotPassword(String email) async {
    final response = await _client.post(
      ApiConstants.forgotPassword,
      {'email': email},
    );
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] as String? ?? '요청에 실패했습니다');
    }
  }

  Future<void> verifyResetCode({
    required String email,
    required String code,
  }) async {
    final response = await _client.get(
      ApiConstants.verifyResetCode,
      queryParams: {'email': email, 'code': code},
    );

    if (response.statusCode == 200) return;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['message'] as String? ?? '코드 확인에 실패했습니다');
  }

  Future<void> resetPassword({
    required String email,
    required String code,
    required String newPassword,
  }) async {
    final response = await _client.post(ApiConstants.resetPassword, {
      'email': email,
      'code': code,
      'newPassword': newPassword,
    });

    if (response.statusCode == 200) return;
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['message'] as String? ?? '비밀번호 재설정에 실패했습니다');
  }
}
