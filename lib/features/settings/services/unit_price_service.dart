import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/settings/models/unit_price.dart';

class UnitPriceService {
  final _client = ApiClient();

  String _endpoint(int factoryId, int processId) =>
      '${ApiConstants.factory_}/$factoryId/processes/$processId/unit-prices';

  Future<List<UnitPrice>> getUnitPrices(int factoryId, int processId) async {
    final response = await _client.get(_endpoint(factoryId, processId));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List? ?? [];
      return dataList
          .map((e) => UnitPrice.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('단가 조회 실패: ${response.statusCode}');
  }

  Future<void> saveUnitPrices(int factoryId, int processId, List<Map<String, dynamic>> entries) async {
    final response = await _client.put(
      '${ApiConstants.factory_}/$factoryId/processes/$processId/unit-prices',
      {'entries': entries},
    );
    if (response.statusCode != 200) {
      throw Exception('단가 저장 실패: ${response.statusCode}');
    }
  }
}