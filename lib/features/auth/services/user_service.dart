import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/auth/models/update_user_request.dart';

class UserService {
  final _client = ApiClient();

  Future<void> updateMe(UpdateUserRequest request) async {
    final response = await _client.patch(ApiConstants.updateMe, request.toJson());
    if (response.statusCode != 200) {
      throw Exception('회원정보 수정 실패: ${response.statusCode}');
    }
  }
}