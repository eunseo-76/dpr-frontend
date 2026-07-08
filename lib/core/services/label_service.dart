import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';

class LabelService {
  final _client = ApiClient();

  Future<Map<String, String>> getLabels() async {
    final response = await _client.get(ApiConstants.labels);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return {
        for (final e in dataList)
          (e as Map<String, dynamic>)['labelKey'] as String:
              e['labelText'] as String,
      };
    }
    throw Exception('라벨 조회 실패: ${response.statusCode}');
  }
}
