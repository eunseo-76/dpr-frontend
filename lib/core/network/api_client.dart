import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/utils/token_storage.dart';
import 'package:http/http.dart' as http;

class ApiClient {
  Future<http.Response> post(String endpoint, Map<String, dynamic> body) async {
    final token = await TokenStorage.getToken();
    final uri = Uri.parse('${ApiConstants.baseUrl}$endpoint');
    return http.get(
      uri,
      headers: {
        'Content-Type': 'application/json',
        if (token != null) 'Authorization': 'Bearer $token',
      },
    );
  }
}
