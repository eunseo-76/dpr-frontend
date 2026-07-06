import 'dart:convert';
import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/network/api_client.dart';
import 'package:dpr_frontend/features/settings/models/user_member.dart';
import 'package:dpr_frontend/features/settings/models/invitation.dart';

class InvitationService {
  final ApiClient _client = ApiClient();

  Future<List<UserMember>> getUsers() async {
    final response = await _client.get(ApiConstants.users);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => UserMember.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('회원 목록 조회 실패');
  }

  Future<List<Invitation>> getInvitations() async {
    final response = await _client.get(ApiConstants.invitations);
    if (response.statusCode == 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      final dataList = body['data'] as List;
      return dataList
          .map((e) => Invitation.fromJson(e as Map<String, dynamic>))
          .toList();
    }
    throw Exception('초대 목록 조회 실패');
  }

  Future<void> deleteUsers(List<int> userIds) async {
    final response = await _client.delete(ApiConstants.users, {
      'userIds': userIds,
    });
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? '회원 삭제 실패');
    }
  }

  Future<void> assignFactory({
    required List<int> userIds,
    required int factoryId,
  }) async {
    final response = await _client.post(ApiConstants.assignFactory, {
      'userIds': userIds,
      'factoryId': factoryId,
    });
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? '공장 배치 실패');
    }
  }

  Future<void> syncManagerFactories({
    required int userId,
    required List<int> factoryIds,
  }) async {
    final response = await _client.put('${ApiConstants.users}/$userId/factories', {
      'ids': factoryIds,
    });
    if (response.statusCode != 200) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      throw Exception(body['message'] ?? '담당 공장 수정 실패');
    }
  }

  Future<Map<String, dynamic>> createInvitation({
    required String email,
    required String role,
    required String position,
    required int factoryId,
  }) async {
    final response = await _client.post(ApiConstants.invitations, {
      'email': email,
      'role': role,
      'position': position,
      'factoryId': factoryId,
    });
    if (response.statusCode == 200 || response.statusCode == 201) {
      final body = jsonDecode(response.body) as Map<String, dynamic>;
      return body['data'] as Map<String, dynamic>;
    }
    final body = jsonDecode(response.body) as Map<String, dynamic>;
    throw Exception(body['message'] ?? '초대 생성 실패');
  }
}
