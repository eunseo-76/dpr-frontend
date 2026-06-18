import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/client/models/factory_client.dart';
import 'package:dpr_frontend/features/settings/models/factory_unit.dart';
import 'package:dpr_frontend/features/utility/models/factory_process.dart';

class FactoryMappingService {
  final _client = ApiClient();

  Future<List<FactoryProcess>> getFactoryProcesses() async {
    final response = await _client.get(ApiConstants.factoryProcess);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => FactoryProcess.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('공장-공정 매핑 조회 실패: ${response.statusCode}');
  }

  Future<List<FactoryUnit>> getFactoryUnits() async {
    final response = await _client.get(ApiConstants.factoryUnit);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => FactoryUnit.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('공장-단위 매핑 조회 실패: ${response.statusCode}');
  }

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

  Future<void> syncProcesses(int factoryId, List<int> ids) async {
    final response = await _client.put(
      '${ApiConstants.factory_}/$factoryId/processes',
      {'ids': ids},
    );
    if (response.statusCode != 200) {
      throw Exception('공정 매핑 저장 실패: ${response.statusCode}');
    }
  }

  Future<void> syncUnits(int factoryId, List<int> ids) async {
    final response = await _client.put(
      '${ApiConstants.factory_}/$factoryId/units',
      {'ids': ids},
    );
    if (response.statusCode != 200) {
      throw Exception('단위 매핑 저장 실패: ${response.statusCode}');
    }
  }

  Future<void> syncClients(int factoryId, List<int> ids) async {
    final response = await _client.put(
      '${ApiConstants.factory_}/$factoryId/clients',
      {'ids': ids},
    );
    if (response.statusCode != 200) {
      throw Exception('업체 매핑 저장 실패: ${response.statusCode}');
    }
  }
}