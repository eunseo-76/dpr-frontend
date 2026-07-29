import 'package:fprs_frontend/core/utils/toast.dart';
import 'package:fprs_frontend/core/widgets/confirm_dialog.dart';
import 'package:fprs_frontend/core/utils/user_storage.dart';
import 'package:fprs_frontend/core/widgets/form_action_bar.dart';
import 'package:fprs_frontend/core/widgets/shake_field.dart';
import 'package:fprs_frontend/features/auth/models/update_user_request.dart';
import 'package:fprs_frontend/features/auth/services/user_service.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _nameKey = GlobalKey<ShakeFieldState>();
  final _userService = UserService();
  bool _isLoading = false;
  String _initialName = '';
  String _initialNickname = '';

  @override
  void initState() {
    super.initState();
    _loadCurrentInfo();
    _nameController.addListener(() => setState(() {}));
    _nicknameController.addListener(() => setState(() {}));
  }

  Future<void> _loadCurrentInfo() async {
    await _userService.refreshUserInfo();
    final name = await UserStorage.getName();
    final nickname = await UserStorage.getNickname();
    if (mounted) {
      setState(() {
        _initialName = name ?? '';
        _initialNickname = nickname ?? '';
        _nameController.text = _initialName;
        _nicknameController.text = _initialNickname;
      });
    }
  }

  bool get _hasChanges =>
      _nameController.text.trim() != _initialName ||
      _nicknameController.text.trim() != _initialNickname;

  Future<bool> _onWillPop() async {
    if (!_hasChanges) return true;
    return confirmDiscardChanges(context);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    _nameKey.currentState?.clearError();

    final name = _nameController.text.trim();
    if (name.isEmpty) {
      _nameKey.currentState?.showError('이름을 입력해주세요');
      return;
    }

    setState(() => _isLoading = true);

    final nickname = _nicknameController.text.trim();
    try {
      await _userService.updateMe(
        UpdateUserRequest(
          name: name,
          nickname: nickname,
        ),
      );
      await UserStorage.updateName(name);
      await UserStorage.updateNickname(nickname);
      if (!mounted) return;
      showToast(context, '수정되었습니다', isError: false);
      Navigator.pop(context);
    } catch (e) {
      if (!mounted) return;
      showToast(context, '수정 실패: $e');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _onWillPop();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
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
                    onPressed: () async {
                      final shouldPop = await _onWillPop();
                      if (shouldPop && context.mounted) Navigator.pop(context);
                    },
                  ),
                  const Expanded(
                    child: Text(
                      '회원정보 수정',
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
                    FormActionBar(
                      hasChanges: _hasChanges,
                      isLoading: _isLoading,
                      onSave: _submit,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    ),
    );
  }
}