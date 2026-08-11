import 'dart:convert';

import 'package:fprs_frontend/core/constants/api_constants.dart';
import 'package:fprs_frontend/core/utils/token_storage.dart';
import 'package:http/http.dart' as http;

const _timeout = Duration(seconds: 15);

http.Response _onTimeout() {
  throw Exception('서버 응답이 없습니다. 잠시 후 다시 시도해주세요.');
}

class ApiClient {
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return http.post(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body), // body의 Map 객체를 json string으로 변환
    ).timeout(_timeout, onTimeout: _onTimeout);
  }

  Future<http.Response> delete(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return http.delete(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(_timeout, onTimeout: _onTimeout);
  }

  Future<http.Response> patch(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return http.patch(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(_timeout, onTimeout: _onTimeout);
  }

  Future<http.Response> put(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return http.put(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
      body: jsonEncode(body),
    ).timeout(_timeout, onTimeout: _onTimeout);
  }

  Future<http.Response> get(String endpoint,
      {Map<String, String>? queryParams}) async {
    final token = await TokenStorage.getToken();
    final base = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    final uri = queryParams != null
        ? base.replace(queryParameters: queryParams)
        : base;
    return http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    ).timeout(_timeout, onTimeout: _onTimeout);
  }
}
