import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/production/models/production.dart';

class ProductionService {
  final _client = ApiClient();

  Future<List<Production>> getProductionList() async {
    final response = await _client.get(ApiConstants.production);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => Production.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('생산실적 조회 실패: ${response.statusCode}');
  }
}
