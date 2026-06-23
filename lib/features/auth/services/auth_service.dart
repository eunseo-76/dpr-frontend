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

    if (response.statusCode == 200) {
      // json String 타입의 response.body(accesstoken)을 map 으로 변환 -> LonginResponse 객체로 변환
      final body = jsonDecode(response.body) as Map<String, dynamic>;
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
    throw Exception('로그인 실패: ${response.statusCode}');
  }

  Future<Map<String, dynamic>> verifyInviteCode(String code) async {
    final response = await _client.get(
      ApiConstants.invite,
      queryParams: {'code': code},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>;
    }

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final errorCode = body['code'] as String? ?? 'UNKNOWN';
    switch (errorCode) {
      case 'INVITATION_NOT_FOUND':
        throw Exception('존재하지 않는 초대코드입니다');
      case 'INVITATION_EXPIRED':
        throw Exception('만료된 초대코드입니다');
      case 'INVITATION_ALREADY_USED':
        throw Exception('이미 사용된 초대코드입니다');
      default:
        throw Exception('초대코드 확인 실패: ${response.statusCode}');
    }
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

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
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

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final errorCode = body['code'] as String? ?? 'UNKNOWN';
    switch (errorCode) {
      case 'EMAIL_ALREADY_EXISTS':
        throw Exception('이미 가입된 이메일입니다');
      default:
        throw Exception('가입 실패: ${response.statusCode}');
    }
  }

  Future<void> withdraw(String password) async {
    final response = await _client.delete(
      ApiConstants.updateMe,
      {'password': password},
    );

    if (response.statusCode == 200) return;

    final body = jsonDecode(response.body) as Map<String, dynamic>;
    final errorCode = body['code'] as String? ?? 'UNKNOWN';
    switch (errorCode) {
      case 'INVALID_PASSWORD':
        throw Exception('비밀번호가 일치하지 않습니다');
      case 'OWNER_CANNOT_WITHDRAW':
        throw Exception('대표 계정은 탈퇴할 수 없습니다');
      default:
        throw Exception('탈퇴 실패: ${response.statusCode}');
    }
  }

  Future<void> forgotPassword(String email) async {
    final response = await _client.post(
      ApiConstants.forgotPassword,
      {'email': email},
    );
    if (response.statusCode != 200) {
      throw Exception('요청 실패: ${response.statusCode}');
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
    final errorCode = body['code'] as String? ?? 'UNKNOWN';
    switch (errorCode) {
      case 'RESET_CODE_NOT_FOUND':
        throw Exception('인증 코드가 올바르지 않습니다');
      case 'RESET_CODE_EXPIRED':
        throw Exception('인증 코드가 만료되었습니다. 다시 요청해주세요');
      default:
        throw Exception('코드 확인 실패: ${response.statusCode}');
    }
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
    final errorCode = body['code'] as String? ?? 'UNKNOWN';
    switch (errorCode) {
      case 'RESET_CODE_NOT_FOUND':
        throw Exception('인증 코드가 올바르지 않습니다');
      case 'RESET_CODE_EXPIRED':
        throw Exception('인증 코드가 만료되었습니다. 다시 요청해주세요');
      default:
        throw Exception('비밀번호 재설정 실패: ${response.statusCode}');
    }
  }
}
