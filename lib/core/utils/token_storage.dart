import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

class TokenStorage {
  static const _key = 'auth_token';
  static const _storage = FlutterSecureStorage();

  static Future<void> saveToken(String token) async {
    await _storage.write(key: _key, value: token);
  }

  static Future<String?> getToken() async {
    final token = await _storage.read(key: _key);
    if (token != null) return token;

    // SharedPreferences 시절 토큰 1회 마이그레이션 (구버전 설치본 대응)
    final prefs = await SharedPreferences.getInstance();
    final legacyToken = prefs.getString(_key);
    if (legacyToken != null) {
      await _storage.write(key: _key, value: legacyToken);
      await prefs.remove(_key);
    }
    return legacyToken;
  }

  static Future<void> clearToken() async {
    await _storage.delete(key: _key);
  }
}
