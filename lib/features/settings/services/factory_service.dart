import 'dart:convert';

import 'package:fprs_frontend/core/constants/api_constants.dart';
import 'package:fprs_frontend/core/network/api_client.dart';
import 'package:fprs_frontend/features/settings/models/factory_shift.dart';

class FactoryService {
  final _client = ApiClient();

  Future<FactoryShift?> getFactoryShift(int factoryId) async {
    // 목록(/api/factories)에서 factoryId로 찾기
    final response = await _client.get(ApiConstants.factory_);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = (body['data'] as List).cast<Map<String, dynamic>>();
      final match = dataList.where((e) => e['factoryId'] == factoryId);
      if (match.isEmpty) return null;
      return FactoryShift.fromJson(match.first);
    }
    return null;
  }
}