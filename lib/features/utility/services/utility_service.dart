import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/utility/models/utility.dart';

class UtilityService {
  final _client = ApiClient();

  Future<List<Utility>> getUtilityList({
    required String date,
    required String periodType,
  }) async {

    final response = await _client.get(
      ApiConstants.utility,
      queryParams: {'date': date, 'periodType': periodType},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => Utility.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('전기/용수 조회 실패: ${response.statusCode}');
  }
}