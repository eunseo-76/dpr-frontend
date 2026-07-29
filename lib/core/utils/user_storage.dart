import 'dart:convert';

import 'package:fprs_frontend/core/models/factory_summary.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  // 회원정보수정 등으로 이름이 바뀌면, 화면 이동 경로와 무관하게
  // 이 값을 구독하는 모든 화면(Home, MyPage 등)이 즉시 갱신되도록 함
  static final ValueNotifier<String> nameNotifier = ValueNotifier<String>('');

  static const _role = 'user_role';
  static const _name = 'user_name';
  static const _nickname = 'user_nickname';
  static const _email = 'user_email';
  static const _position = 'user_position';
  static const _companyId = 'user_company_id';
  static const _companyName = 'user_company_name';
  static const _factories = 'user_factories';

  static Future<void> saveUserInfo(
    String role,
    String name,
    String position,
    int companyId,
    String companyName,
    List<FactorySummary> factories, {
    String? nickname,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_role, role);
    await prefs.setString(_name, name);
    nameNotifier.value = name;
    if (nickname != null) await prefs.setString(_nickname, nickname);
    await prefs.setString(_position, position);
    await prefs.setInt(_companyId, companyId);
    await prefs.setString(_companyName, companyName);
    await prefs.setString(
      _factories,
      jsonEncode(factories.map((f) => f.toJson()).toList()),
    );
  }

  // 한 번도 로그인 안 한 경우 sharedPreferences가 비어있음.
  // 키가 없으면 null 반환하기 때문에 ? 필수
  static Future<void> saveEmail(String email) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_email, email);
  }

  static Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_email);
  }

  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_role);
  }

  static bool isAdmin(String? role) => role == 'OWNER' || role == 'MANAGER';

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_name);
  }

  static Future<String?> getNickname() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_nickname);
  }

  static Future<String?> getPosition() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_position);
  }

  static Future<int?> getCompanyId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_companyId);
  }

  static Future<String?> getCompanyName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_companyName);
  }

  static Future<List<FactorySummary>> getFactories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_factories);
    if (raw == null) return [];
    return (jsonDecode(raw) as List)
        .map((e) => FactorySummary.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Future<void> updateName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_name, name);
    nameNotifier.value = name;
  }

  static Future<void> updateNickname(String nickname) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_nickname, nickname);
  }

  static Future<void> clearUserInfo() async {
    nameNotifier.value = '';
    final prefs = await SharedPreferences.getInstance();
    // 성능 차이는 없다는데 await 여러 개는 다 병렬로 묶기로
    await Future.wait({
      prefs.remove(_role),
      prefs.remove(_name),
      prefs.remove(_nickname),
      prefs.remove(_email),
      prefs.remove(_position),
      prefs.remove(_companyId),
      prefs.remove(_companyName),
      prefs.remove(_factories),
    });
  }
}
