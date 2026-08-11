import 'package:flutter/material.dart';
import 'package:fprs_frontend/core/utils/toast.dart';
import 'package:fprs_frontend/core/utils/token_storage.dart';
import 'package:fprs_frontend/core/utils/user_storage.dart';
import 'package:fprs_frontend/features/auth/screens/landing_screen.dart';
import 'package:fprs_frontend/main.dart';

class SessionService {
  static bool _handling = false;

  // 여러 API 호출이 동시에 401을 받아도 로그아웃 처리는 한 번만 실행되도록 가드
  static Future<void> handleExpiredSession() async {
    if (_handling) return;
    _handling = true;

    await TokenStorage.clearToken();
    await UserStorage.clearUserInfo();

    navigatorKey.currentState?.pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => const LandingScreen()),
      (route) => false,
    );

    final context = navigatorKey.currentContext;
    if (context != null && context.mounted) {
      showToast(context, '세션이 만료되었습니다. 다시 로그인해주세요.');
    }

    _handling = false;
  }
}