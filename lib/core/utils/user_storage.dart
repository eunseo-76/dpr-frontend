import 'package:shared_preferences/shared_preferences.dart';

class UserStorage {
  static const _role = 'user_role';
  static const _name = 'user_name';
  static const _position = 'user_position';
  static const _companyId = 'user_company_id';
  static const _companyName = 'user_company_name';
  static const _factoryId = 'user_factory_id';
  static const _factoryName = 'user_factory_name';

  static Future<void> saveUserInfo(
    String role,
    String name,
    String position,
    int companyId,
    String companyName,
    int? factoryId,
    String? factoryName,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_role, role);
    await prefs.setString(_name, name);
    await prefs.setString(_position, position);
    await prefs.setInt(_companyId, companyId);
    await prefs.setString(_companyName, companyName);
    if (factoryId != null) await prefs.setInt(_factoryId, factoryId);
    if (factoryName != null) await prefs.setString(_factoryName, factoryName);
  }

  // 한 번도 로그인 안 한 경우 sharedPreferences가 비어있음.
  // 키가 없으면 null 반환하기 때문에 ? 필수
  static Future<String?> getRole() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_role);
  }

  static Future<String?> getName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_name);
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

  static Future<int?> getFactoryId() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_factoryId);
  }

  static Future<String?> getFactoryName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_factoryName);
  }

  static Future<void> updateName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_name, name);
  }

  static Future<void> clearUserInfo() async {
    final prefs = await SharedPreferences.getInstance();
    // 성능 차이는 없다는데 await 여러 개는 다 병렬로 묶기로
    await Future.wait({
      prefs.remove(_role),
      prefs.remove(_name),
      prefs.remove(_position),
      prefs.remove(_companyId),
      prefs.remove(_factoryId),
    });
  }
}
