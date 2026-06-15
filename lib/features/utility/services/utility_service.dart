import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/utility/models/factory_process.dart';
import 'package:dpr_frontend/features/utility/models/utility.dart';
import 'package:dpr_frontend/features/utility/models/utility_summary.dart';

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

  // 카드 하단 누적합계 (연초 ~ date)
  Future<List<UtilitySummary>> getUtilitySummary({
    required String groupBy,
    required String date,
  }) async {
    final response = await _client.get(
      '${ApiConstants.utility}/summary',
      queryParams: {'groupBy': groupBy, 'date': date},
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List? ?? [];
      return dataList
          .map((e) => UtilitySummary.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('누적합계 조회 실패: ${response.statusCode}');
  }

  // 공장-공정 매핑 (날짜와 무관, 한 번만 불러오면 됨)
  Future<List<FactoryProcess>> getFactoryProcesses() async {
    final response = await _client.get(ApiConstants.factoryProcess);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List? ?? [];
      return dataList
          .map((e) => FactoryProcess.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('공장-공정 매핑 조회 실패: ${response.statusCode}');
  }
}