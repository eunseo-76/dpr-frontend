import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/client/models/factory_client.dart';

class ClientService {
  final _client = ApiClient();

  Future<List<FactoryClient>> getFactoryClients() async {
    final response = await _client.get(ApiConstants.factoryClient);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => FactoryClient.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('공장-업체 매핑 조회 실패: ${response.statusCode}');
  }
}