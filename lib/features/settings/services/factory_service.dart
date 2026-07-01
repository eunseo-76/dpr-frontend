import 'dart:convert';

import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/settings/models/factory_shift.dart';

class FactoryService {
  final _client = ApiClient();

  Future<FactoryShift?> getFactoryShift(int factoryId) async {
    final response = await _client.get('${ApiConstants.factory_}/$factoryId');
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return FactoryShift.fromJson(body['data'] as Map<String, dynamic>);
    }
    return null;
  }
}