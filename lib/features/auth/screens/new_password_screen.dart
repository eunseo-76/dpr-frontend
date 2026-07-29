import 'package:fprs_frontend/core/utils/fade_route.dart';
import 'package:fprs_frontend/core/utils/toast.dart';
import 'package:fprs_frontend/core/utils/validators.dart';
import 'package:fprs_frontend/core/widgets/shake_field.dart';
import 'package:fprs_frontend/features/auth/screens/login_screen.dart';
import 'package:fprs_frontend/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';

class NewPasswordScreen extends StatefulWidget {
  final String email;
  final String code;

  const NewPasswordScreen({super.key, required this.email, required this.code});

  @override
  State<NewPasswordScreen> createState() => _NewPasswordScreenState();
}

class _NewPasswordScreenState extends State<NewPasswordScreen> {
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _passwordKey = GlobalKey<ShakeFieldState>();
  final _passwordConfirmKey = GlobalKey<ShakeFieldState>();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  @override
  void dispose() {
    _passwordController.dispose();
    _passwordConfirmController.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    _passwordKey.currentState?.clearError();
    _passwordConfirmKey.currentState?.clearError();

    bool hasError = false;
    final passwordError = Validators.validatePassword(_passwordController.text);
    if (passwordError != null) {
      _passwordKey.currentState?.showError(passwordError);
      hasError = true;
    }
    if (_passwordConfirmController.text.isEmpty) {
      _passwordConfirmKey.currentState?.showError('비밀번호 확인을 입력해주세요');
      hasError = true;
    } else if (_passwordController.text != _passwordConfirmController.text) {
      _passwordConfirmKey.currentState?.showError('비밀번호가 일치하지 않습니다');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      await _authService.resetPassword(
        email: widget.email,
        code: widget.code,
        newPassword: _passwordController.text,
      );
      if (!mounted) return;
      showToast(context, '비밀번호가 변경되었습니다', isError: false);
      Navigator.pushAndRemoveUntil(
        context,
        fadeRoute(const LoginScreen()),
        (route) => route.isFirst,
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
                      '새 비밀번호',
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
                      key: _passwordKey,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: '새 비밀번호',
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
                    ),
                    const SizedBox(height: 24),
                    ShakeField(
                      key: _passwordConfirmKey,
                      controller: _passwordConfirmController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: '새 비밀번호 확인',
                        hintStyle: TextStyle(color: Colors.grey[400]),
                        enabledBorder: UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.grey[300]!),
                        ),
                        focusedBorder: const UnderlineInputBorder(
                          borderSide: BorderSide(color: Colors.black87),
                        ),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscureConfirm ? Icons.visibility_off : Icons.visibility,
                            color: Colors.grey[500],
                            size: 20,
                          ),
                          onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                        ),
                      ),
                      onSubmitted: (_) => _resetPassword(),
                    ),
                    const SizedBox(height: 8),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        '영문 + 숫자 + 특수문자 포함 8자 이상',
                        style: TextStyle(color: Colors.grey[400], fontSize: 12),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _resetPassword,
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
                                '변경하기',
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