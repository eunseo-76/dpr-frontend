import 'package:dpr_frontend/core/utils/token_storage.dart';
import 'package:dpr_frontend/features/auth/screens/landing_screen.dart';
import 'package:dpr_frontend/main_screen.dart';
import 'package:flutter/material.dart';

// 앱 시작 시 토큰 유무를 확인해 초기 화면을 결정한다.
// 토큰 있음 -> MainScreen (자동 로그인)
// 토큰 없음 -> LandingScreen
class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _checkLogin();
  }

  Future<void> _checkLogin() async {
    final token = await TokenStorage.getToken();

    if (!mounted) return;
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (_) =>
            token != null ? const MainScreen() : const LandingScreen(),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      body: Center(child: CircularProgressIndicator()),
    );
  }
}