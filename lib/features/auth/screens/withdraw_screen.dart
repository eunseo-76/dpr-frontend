import 'package:fprs_frontend/core/utils/toast.dart';
import 'package:fprs_frontend/core/widgets/confirm_dialog.dart';
import 'package:fprs_frontend/core/widgets/shake_field.dart';
import 'package:fprs_frontend/core/utils/token_storage.dart';
import 'package:fprs_frontend/core/utils/user_storage.dart';
import 'package:fprs_frontend/features/auth/screens/landing_screen.dart';
import 'package:fprs_frontend/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';

class WithdrawScreen extends StatefulWidget {
  const WithdrawScreen({super.key});

  @override
  State<WithdrawScreen> createState() => _WithdrawScreenState();
}

class _WithdrawScreenState extends State<WithdrawScreen> {
  final _passwordController = TextEditingController();
  final _passwordKey = GlobalKey<ShakeFieldState>();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;

  Future<void> _withdraw() async {
    _passwordKey.currentState?.clearError();
    if (_passwordController.text.isEmpty) {
      _passwordKey.currentState?.showError('비밀번호를 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      if (!mounted) return;
      final confirmed = await showConfirmDialog(
        context,
        title: '회원탈퇴',
        content: '정말로 탈퇴하시겠습니까?',
        confirmLabel: '탈퇴',
        isDestructive: true,
      );

      if (confirmed != true) {
        setState(() => _isLoading = false);
        return;
      }

      await _authService.withdraw(_passwordController.text);
      await TokenStorage.clearToken();
      await UserStorage.clearUserInfo();

      if (!mounted) return;
      showToast(context, '탈퇴되었습니다', isError: false);
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const LandingScreen()),
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
                      '회원탈퇴',
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
                    Text(
                      '탈퇴 시 이메일·비밀번호 등 개인정보는\n즉시 마스킹 처리되며, 같은 이메일로\n재가입할 수 없습니다\n\n탈퇴 후 재가입하려면 관리자에게 문의하세요.\n (eunseolee19@gmail.com)',
                      textAlign: TextAlign.center,
                      style: TextStyle(color: Colors.grey[600], fontSize: 14, height: 1.5),
                    ),
                    const SizedBox(height: 40),
                    ShakeField(
                      key: _passwordKey,
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      onSubmitted: (_) => _withdraw(),
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
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _withdraw,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.red[600],
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.red[200],
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
                                '탈퇴하기',
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