import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/models/production_upsert_entry.dart';

class ProductionService {
  final _client = ApiClient();

  Future<List<Production>> getProductionList({
    required String date,
    required String periodType,
  }) async {
    final response = await _client.get(
      ApiConstants.production,
      queryParams: {'date': date, 'periodType': periodType},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => Production.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('생산실적 조회 실패: ${response.statusCode}');
  }

  Future<int> upsertProductions({
    required String date,
    required List<ProductionUpsertEntry> entries,
  }) async {
    final response = await _client.post(ApiConstants.production, {
      'date': date,
      'entries': entries.map((e) => e.toJson()).toList(),
    });

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['data'] as int;
    }
    throw Exception('생산실적 저장 실패: ${response.statusCode}');
  }

  Future<void> deleteProductions(List<int> productionIds) async {
    final response = await _client.delete(ApiConstants.production, {
      'productionIds': productionIds,
    });

    if (response.statusCode != 200) {
      throw Exception('생산실적 삭제 실패: ${response.statusCode}');
    }
  }
}
