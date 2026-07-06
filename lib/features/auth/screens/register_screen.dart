import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/utils/validators.dart';
import 'package:dpr_frontend/core/widgets/shake_field.dart';
import 'package:dpr_frontend/features/auth/services/auth_service.dart';
import 'package:dpr_frontend/main_screen.dart';
import 'package:flutter/material.dart';

class RegisterScreen extends StatefulWidget {
  final String inviteCode;
  final String email;
  final String companyName;
  final String? factoryName;
  final String role;
  final String position;

  const RegisterScreen({
    super.key,
    required this.inviteCode,
    required this.email,
    required this.companyName,
    this.factoryName,
    required this.role,
    required this.position,
  });

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _passwordController = TextEditingController();
  final _passwordConfirmController = TextEditingController();
  final _nameKey = GlobalKey<ShakeFieldState>();
  final _passwordKey = GlobalKey<ShakeFieldState>();
  final _passwordConfirmKey = GlobalKey<ShakeFieldState>();
  final _authService = AuthService();
  bool _isLoading = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  Future<void> _register() async {
    _nameKey.currentState?.clearError();
    _passwordKey.currentState?.clearError();
    _passwordConfirmKey.currentState?.clearError();

    bool hasError = false;
    if (_nameController.text.trim().isEmpty) {
      _nameKey.currentState?.showError('이름을 입력해주세요');
      hasError = true;
    }
    final passwordError = Validators.validatePassword(_passwordController.text);
    if (passwordError != null) {
      _passwordKey.currentState?.showError(passwordError);
      hasError = true;
    }
    if (_passwordController.text != _passwordConfirmController.text) {
      _passwordConfirmKey.currentState?.showError('비밀번호가 일치하지 않습니다');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _isLoading = true);

    try {
      await _authService.register(
        inviteCode: widget.inviteCode,
        name: _nameController.text.trim(),
        nickname: _nicknameController.text.trim(),
        password: _passwordController.text,
      );

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
                      '회원가입',
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
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: Colors.grey[50],
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _infoRow('이메일', widget.email),
                          if (widget.factoryName != null) ...[
                            const SizedBox(height: 8),
                            _infoRow('공장', widget.factoryName!),
                          ],
                          const SizedBox(height: 8),
                          _infoRow('직급', widget.position),
                        ],
                      ),
                    ),
                    const SizedBox(height: 32),
                    ShakeField(
                      key: _nameKey,
                      controller: _nameController,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: '이름',
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
                    TextField(
                      controller: _nicknameController,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: '닉네임 (선택)',
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
                    ),
                    const SizedBox(height: 24),
                    ShakeField(
                      key: _passwordConfirmKey,
                      controller: _passwordConfirmController,
                      obscureText: _obscureConfirm,
                      style: const TextStyle(fontSize: 16, color: Colors.black87),
                      decoration: InputDecoration(
                        hintText: '비밀번호 확인',
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
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '영문 + 숫자 + 특수문자(@\$!%*#?&) 포함 8자 이상',
                      style: TextStyle(color: Colors.grey[400], fontSize: 12),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _register,
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
                                '가입하기',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                              ),
                      ),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Row(
      children: [
        SizedBox(
          width: 48,
          child: Text(
            label,
            style: TextStyle(color: Colors.grey[500], fontSize: 13),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            value,
            style: const TextStyle(
              color: Colors.black87,
              fontSize: 14,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }
}
