import 'dart:convert';

import 'package:fprs_frontend/core/constants/api_constants.dart';
import 'package:fprs_frontend/core/network/api_client.dart';
import 'package:fprs_frontend/features/settings/models/process_unit_price.dart';

class UnitPriceService {
  final _client = ApiClient();

  String _clientEndpoint(int factoryId, int clientId) =>
      '${ApiConstants.factory_}/$factoryId/clients/$clientId/unit-prices';

  Future<List<ProcessUnitPrice>> getUnitPricesByClient(int factoryId, int clientId) async {
    final response = await _client.get(_clientEndpoint(factoryId, clientId));
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List? ?? [];
      return dataList
          .map((e) => ProcessUnitPrice.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('단가 조회 실패: ${response.statusCode}');
  }

  Future<void> saveUnitPricesByClient(int factoryId, int clientId, List<Map<String, dynamic>> entries) async {
    final response = await _client.put(
      _clientEndpoint(factoryId, clientId),
      {'entries': entries},
    );
    if (response.statusCode != 200) {
      throw Exception('단가 저장 실패: ${response.statusCode}');
    }
  }
}
