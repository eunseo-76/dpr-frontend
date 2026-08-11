import 'dart:convert';

import 'package:fprs_frontend/core/constants/api_constants.dart';
import 'package:fprs_frontend/core/services/session_service.dart';
import 'package:fprs_frontend/core/utils/token_storage.dart';
import 'package:http/http.dart' as http;

const _timeout = Duration(seconds: 15);

http.Response _onTimeout() {
  throw Exception('서버 응답이 없습니다. 잠시 후 다시 시도해주세요.');
}

// 에러 응답 body에서 message를 꺼낼 때 사용. nginx 502 등으로 body가
// JSON이 아닐 수 있어 실패 시 원문 대신 fallback 메시지를 반환
String extractErrorMessage(http.Response response, String fallback) {
  try {
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    return body['message'] as String? ?? fallback;
  } catch (_) {
    return fallback;
  }
}

class ApiClient {
  // 모든 요청이 이 지점을 거치도록 해서 401(세션 만료)을 여기서 감지
  // 토큰 없이 보낸 요청(e.g. 로그인)의 401은 세션 만료가 아니라 인증 실패라 제외함
  Future<http.Response> _send(
    String? token,
    Future<http.Response> Function() request,
  ) async {
    final response = await request();
    if (response.statusCode == 401 && token != null) {
      await SessionService.handleExpiredSession();
    }
    return response;
  }

  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return _send(
      token,
      () => http.post(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body), // body의 Map 객체를 json string으로 변환
      ).timeout(_timeout, onTimeout: _onTimeout),
    );
  }

  Future<http.Response> delete(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return _send(
      token,
      () => http.delete(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(_timeout, onTimeout: _onTimeout),
    );
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return _send(
      token,
      () => http.patch(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(_timeout, onTimeout: _onTimeout),
    );
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return _send(
      token,
      () => http.put(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
        body: jsonEncode(body),
      ).timeout(_timeout, onTimeout: _onTimeout),
    );
  }

  Future<http.Response> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final token = await TokenStorage.getToken();
    final base = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final uri = queryParams != null
        ? base.replace(queryParameters: queryParams)
        : base;
    return _send(
      token,
      () => http.get(
        uri,
        headers: {
          'Content-Type': 'application/json',
          if (token != null) 'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout, onTimeout: _onTimeout),
    );
  }
}