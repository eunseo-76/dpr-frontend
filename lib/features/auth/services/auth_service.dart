import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/core/utils/token_storage.dart';
import 'package:dpr_frontend/features/auth/models/login_request.dart';
import 'package:dpr_frontend/features/auth/models/login_response.dart';

class AuthService {
  final _client = ApiClient();

  Future<LoginResponse> login(LoginRequest request) async {
    final response = await _client.post(ApiConstants.login, request.toJson());

    if (response.statusCode == 200) {
      // json String 타입의 response.body(accesstoken)을 map 으로 변환 -> LonginResponse 객체로 변환
      final loginResponse = LoginResponse.fromJson(jsonDecode(response.body));
      await TokenStorage.saveToken(loginResponse.accessToken);
      return loginResponse;
    }
    throw Exception('로그인 실패: ${response.statusCode}');
  }
}
