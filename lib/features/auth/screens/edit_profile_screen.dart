import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/features/auth/models/update_user_request.dart';
import 'package:dpr_frontend/features/auth/services/user_service.dart';
import 'package:flutter/material.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({super.key});

  @override
  State<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  final _nameController = TextEditingController();
  final _nicknameController = TextEditingController();
  final _userService = UserService();
  bool _isLoading = false;
  String? _nameError;

  @override
  void initState() {
    super.initState();
    _loadCurrentInfo();
  }

  Future<void> _loadCurrentInfo() async {
    final name = await UserStorage.getName();
    if (mounted) {
      _nameController.text = name ?? '';
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _nicknameController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _nameError = '이름을 입력해주세요');
      return;
    }
    setState(() {
      _nameError = null;
      _isLoading = true;
    });

    try {
      await _userService.updateMe(
        UpdateUserRequest(
          name: name,
          nickname: _nicknameController.text.trim(),
        ),
      );
      await UserStorage.updateName(name);
      if (!mounted) return;
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
    return Scaffold(
      appBar: AppBar(
        title: const Text('회원정보 수정'),
        actions: [
          TextButton(
            onPressed: _isLoading ? null : _submit,
            child: _isLoading
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('저장'),
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            TextField(
              controller: _nameController,
              decoration: InputDecoration(
                labelText: '이름',
                errorText: _nameError,
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _nicknameController,
              decoration: const InputDecoration(
                labelText: '닉네임 (선택)',
              ),
            ),
          ],
        ),
      ),
    );
  }
}