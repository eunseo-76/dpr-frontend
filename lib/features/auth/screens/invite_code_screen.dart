import 'package:dpr_frontend/core/utils/fade_route.dart';
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
  final _focusNode = FocusNode();
  final _authService = AuthService();
  final int _codeLength = 6;
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _codeController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  Future<void> _verifyCode() async {
    final code = _codeController.text.trim();
    if (code.length < _codeLength) {
      setState(() => _errorMessage = '초대코드 $_codeLength자리를 입력해주세요');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

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
      setState(() => _errorMessage = e.toString().replaceFirst('Exception: ', ''));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final code = _codeController.text.toUpperCase();

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
                    // 숨겨진 TextField + 박스 UI
                    GestureDetector(
                      onTap: () => _focusNode.requestFocus(),
                      child: Stack(
                        children: [
                          // 박스 UI (먼저 배치하여 높이 결정)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: List.generate(_codeLength, (i) {
                              final hasChar = i < code.length;
                              final isCursor = i == code.length && _focusNode.hasFocus;
                              return Container(
                                width: 48,
                                height: 56,
                                decoration: BoxDecoration(
                                  color: hasChar ? Colors.grey[100] : Colors.white,
                                  borderRadius: BorderRadius.circular(14),
                                  border: Border.all(
                                    color: isCursor
                                        ? Colors.black87
                                        : hasChar
                                            ? Colors.grey[300]!
                                            : Colors.grey[300]!,
                                    width: isCursor ? 1.5 : 1,
                                  ),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  hasChar ? code[i] : '',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.black87,
                                  ),
                                ),
                              );
                            }),
                          ),
                          // 숨겨진 실제 입력 필드 (박스 위에 겹쳐서 동일 크기)
                          Positioned.fill(
                            child: Opacity(
                              opacity: 0,
                              child: TextField(
                                controller: _codeController,
                                focusNode: _focusNode,
                                maxLength: _codeLength,
                                textCapitalization: TextCapitalization.characters,
                                autofocus: true,
                                decoration: const InputDecoration(counterText: ''),
                                onSubmitted: (_) => _verifyCode(),
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                    if (_errorMessage != null)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(12),
                        margin: const EdgeInsets.only(bottom: 16),
                        decoration: BoxDecoration(
                          color: Colors.red[50],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _errorMessage!,
                          style: TextStyle(color: Colors.red[700], fontSize: 13),
                        ),
                      ),
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