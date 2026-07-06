import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';

class UnitService {
  final _client = ApiClient();

  Future<List<Unit>> getUnitList({int? factoryId}) async {
    final endPoint = factoryId != null
        ? '${ApiConstants.unit}?factoryId=$factoryId'
        : ApiConstants.unit;

    final response = await _client.get(endPoint);

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => Unit.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('단위 조회 실패: ${response.statusCode}');
  }
}
