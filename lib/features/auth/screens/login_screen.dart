import 'package:dpr_frontend/core/utils/fade_route.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/core/utils/validators.dart';
import 'package:dpr_frontend/core/widgets/shake_field.dart';
import 'package:dpr_frontend/features/auth/models/login_request.dart';
import 'package:dpr_frontend/features/auth/screens/forgot_password_screen.dart';
import 'package:dpr_frontend/features/auth/services/auth_service.dart';
import 'package:dpr_frontend/main_screen.dart';
import 'package:flutter/material.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _emailKey = GlobalKey<ShakeFieldState>();
  final _passwordKey = GlobalKey<ShakeFieldState>();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _login() async {
    _emailKey.currentState?.clearError();
    _passwordKey.currentState?.clearError();

    bool hasError = false;
    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) {
      _emailKey.currentState?.showError(emailError);
      hasError = true;
    }
    if (_passwordController.text.isEmpty) {
      _passwordKey.currentState?.showError('비밀번호를 입력해주세요');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      final email = _emailController.text.trim();
      await _authService.login(
        LoginRequest(
          email: email,
          password: _passwordController.text,
        ),
      );
      await UserStorage.saveEmail(email);

      if (!mounted) return;
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const MainScreen()),
        (route) => false,
      );
    } catch (e) {
      if (mounted) showToast(context, e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 8),
              child: Row(
                children: [
                  IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.black87),
                    onPressed: () => Navigator.pop(context),
                  ),
                  const Expanded(
                    child: Text(
                      '로그인',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w600,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  const SizedBox(width: 48),
                ],
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  children: [
                    const SizedBox(height: 32),
                    ShakeField(
                      key: _emailKey,
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: '이메일',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black87),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ShakeField(
                      key: _passwordKey,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: '비밀번호',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black87),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                      onSubmitted: (_) => _login(),
                    ),
                    const SizedBox(height: 16),
                    Align(
                      alignment: Alignment.centerRight,
                      child: GestureDetector(
                        onTap: () => Navigator.push(
                          context,
                          fadeRoute(const ForgotPasswordScreen()),
                        ),
                        child: Text(
                          '비밀번호 재설정',
                          style: TextStyle(
                            color: Colors.blue[600],
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _login,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.black87,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey[300],
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                          elevation: 0,
                        ),
                        child: _isLoading
                            ? const SizedBox(
                                width: 20, height: 20,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Text(
                                '로그인',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}