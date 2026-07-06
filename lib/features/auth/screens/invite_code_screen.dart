import 'package:dpr_frontend/core/utils/fade_route.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/widgets/pin_code_field.dart';
import 'package:dpr_frontend/features/auth/screens/register_screen.dart';
import 'package:dpr_frontend/features/auth/services/auth_service.dart';
import 'package:flutter/material.dart';

class InviteCodeScreen extends StatefulWidget {
  const InviteCodeScreen({super.key});

  @override
  State<InviteCodeScreen> createState() => _InviteCodeScreenState();
}

class _InviteCodeScreenState extends State<InviteCodeScreen> {
  final _codeController = TextEditingController();
  final _authService = AuthService();
  bool _isLoading = false;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < 6) {
      if (mounted) showToast(context, '초대코드 6자리를 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    try {
      final inviteData = await _authService.verifyInviteCode(code);
      if (!mounted) return;
      Navigator.push(
        context,
        fadeRoute(RegisterScreen(
          inviteCode: code,
          email: inviteData['email'] as String,
          companyName: inviteData['companyName'] as String,
          factoryName: inviteData['factoryName'] as String?,
          role: inviteData['role'] as String,
          position: inviteData['position'] as String,
        )),
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
                      '초대코드 입력',
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
                    const SizedBox(height: 16),
                    Text(
                      '관리자에게 받은 초대코드를 입력하세요',
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 40),
                    PinCodeField(
                      controller: _codeController,
                      onSubmitted: (_) => _verifyCode(),
                    ),
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 48,
                      child: ElevatedButton(
                        onPressed: _isLoading ? null : _verifyCode,
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
                                '확인',
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