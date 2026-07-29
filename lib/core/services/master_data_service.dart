import 'dart:convert';

import 'package:fprs_frontend/core/models/master_data_entity.dart';
import 'package:fprs_frontend/core/network/api_client.dart';

class MasterDataService {
  final String endpoint;
  final String idKey;
  final ApiClient _client = ApiClient();

  MasterDataService({required this.endpoint, required this.idKey});

  Future<List<MasterDataEntity>> getAll() async {
    final response = await _client.get(endpoint);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => MasterDataEntity.fromJson(e as Map<String, dynamic>, idKey))
          .toList();
    }
    throw Exception('목록 조회 실패: ${response.statusCode}');
  }

  Future<void> create(Map<String, dynamic> body) async {
    final response = await _client.post(endpoint, body);
    if (response.statusCode == 200 || response.statusCode == 201) {
      return;
    }
    throw Exception('생성 실패: ${response.statusCode}');
  }

  Future<void> update(int id, Map<String, dynamic> body) async {
    final response = await _client.patch('$endpoint/$id', body);
    if (response.statusCode == 200) {
      return;
    }
    throw Exception('수정 실패: ${response.statusCode}');
  }

  Future<void> delete(int id) async {
    final response = await _client.delete('$endpoint/$id', {});
    if (response.statusCode == 200) {
      return;
    }
    throw Exception('삭제 실패: ${response.statusCode}');
  }
}