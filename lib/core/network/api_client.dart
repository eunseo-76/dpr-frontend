import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/utils/token_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return http.post(
      uri,
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode(body), // body의 Map 객체를 json string으로 변환
    );
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
    );
  }
}
