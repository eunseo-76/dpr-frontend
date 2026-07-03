import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/models/master_data_entity.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/utils/validators.dart';
import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/core/widgets/pin_code_field.dart';
import 'package:dpr_frontend/core/widgets/pop_effect.dart';
import 'package:dpr_frontend/core/widgets/shake_field.dart';
import 'package:dpr_frontend/features/settings/services/invitation_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class InvitationCreateDialog extends StatefulWidget {
  const InvitationCreateDialog({super.key});

  @override
  State<InvitationCreateDialog> createState() => _InvitationCreateDialogState();
}

class _InvitationCreateDialogState extends State<InvitationCreateDialog> {
  final _emailController = TextEditingController();
  final _positionController = TextEditingController();
  final _codeDisplayController = TextEditingController();
  final _emailKey = GlobalKey<ShakeFieldState>();
  final _positionKey = GlobalKey<ShakeFieldState>();
  final _service = InvitationService();

  List<MasterDataEntity> _factories = [];
  int? _selectedFactoryId;
  String _selectedRole = 'STAFF';
  String? _currentUserRole;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _createdInviteCode;
  bool _copyTrigger = false;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _positionController.dispose();
    _codeDisplayController.dispose();
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    final role = await UserStorage.getRole();
    final List<MasterDataEntity> factories;
    if (role == 'MANAGER') {
      final myFactories = await UserStorage.getFactories();
      factories = myFactories
          .map((f) => MasterDataEntity(id: f.factoryId, name: f.factoryName, data: const {}))
          .toList();
    } else {
      factories = await MasterDataService(
        endpoint: ApiConstants.factory_,
        idKey: 'factoryId',
      ).getAll();
    }

    if (!mounted) return;
    setState(() {
      _currentUserRole = role;
      _factories = factories;
      if (factories.isNotEmpty) _selectedFactoryId = factories.first.id;
      _isLoading = false;
    });
  }

  bool get _isManager => _currentUserRole == 'MANAGER';

  Future<void> _submit() async {
    _emailKey.currentState?.clearError();
    _positionKey.currentState?.clearError();

    bool hasError = false;
    final emailError = Validators.validateEmail(_emailController.text);
    if (emailError != null) {
      _emailKey.currentState?.showError(emailError);
      hasError = true;
    }
    if (_positionController.text.trim().isEmpty) {
      _positionKey.currentState?.showError('직급을 입력해주세요');
      hasError = true;
    }
    if (_selectedFactoryId == null) {
      showToast(context, '공장을 선택해주세요');
      hasError = true;
    }
    if (hasError) return;

    setState(() => _isSaving = true);
    try {
      final result = await _service.createInvitation(
        email: _emailController.text.trim(),
        role: _selectedRole,
        position: _positionController.text.trim(),
        factoryId: _selectedFactoryId!,
      );
      if (!mounted) return;
      final code = result['inviteCode'] as String;
      _codeDisplayController.text = code;
      setState(() {
        _createdInviteCode = code;
        _isSaving = false;
      });
    } catch (e) {
      if (mounted) {
        showToast(context, e.toString().replaceFirst('Exception: ', ''));
        setState(() => _isSaving = false);
      }
    }
  }

  Future<void> _copyCode() async {
    setState(() => _copyTrigger = !_copyTrigger);
    await Clipboard.setData(ClipboardData(text: _createdInviteCode!));
    if (mounted) showToast(context, '초대코드가 복사되었습니다', isError: false);
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
      title: Row(
        children: [
          Expanded(
            child: AnimatedSwitcher(
              duration: const Duration(milliseconds: 250),
              child: Align(
                key: ValueKey(_createdInviteCode != null),
                alignment: Alignment.centerLeft,
                child: Text(
                  _createdInviteCode != null ? '초대코드' : '초대하기',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ),
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            onPressed: () => Navigator.pop(context, _createdInviteCode != null ? {'inviteCode': _createdInviteCode} : null),
          ),
        ],
      ),
      contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
      content: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _createdInviteCode != null
            ? _buildCodeView()
            : _buildFormView(),
      ),
      actionsPadding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
      actions: [
        AnimatedSwitcher(
          duration: const Duration(milliseconds: 250),
          child: _createdInviteCode != null
              ? _buildCodeActions()
              : _buildFormActions(),
        ),
      ],
    );
  }

  Widget _buildFormView() {
    return SizedBox(
      key: const ValueKey('form'),
      child: _isLoading
          ? const SizedBox(
              height: 200,
              child: Center(child: CircularProgressIndicator()),
            )
          : SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('이메일',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  ShakeField(
                    key: _emailKey,
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: 'user@example.com',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('직급',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  ShakeField(
                    key: _positionKey,
                    controller: _positionController,
                    style: const TextStyle(fontSize: 15),
                    decoration: InputDecoration(
                      hintText: '예: 팀장, 부장',
                      hintStyle: TextStyle(color: Colors.grey[400]),
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                  ),
                  const SizedBox(height: 16),
                  const Text('역할',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<String>(
                    initialValue: _selectedRole,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: [
                      const DropdownMenuItem(value: 'STAFF', child: Text('멤버')),
                      if (!_isManager)
                        const DropdownMenuItem(value: 'MANAGER', child: Text('매니저')),
                    ],
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedRole = v);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text('공장',
                      style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                  const SizedBox(height: 6),
                  DropdownButtonFormField<int>(
                    initialValue: _selectedFactoryId,
                    decoration: InputDecoration(
                      isDense: true,
                      contentPadding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 12),
                      border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8)),
                    ),
                    items: _factories
                        .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                        .toList(),
                    onChanged: (v) {
                      if (v != null) setState(() => _selectedFactoryId = v);
                    },
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }

  Widget _buildCodeView() {
    return SizedBox(
      key: const ValueKey('code'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 4),
          Text(
            '이 코드를 새로운 회원에게 보내주세요.\n새로운 회원은 앱에서 초대 코드를 통해 회원가입 할 수 있습니다.',
            style: TextStyle(fontSize: 13, color: Colors.grey[600]),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 24),
          IgnorePointer(
            child: PinCodeField(
              controller: _codeDisplayController,
              autofocus: false,
              gap: 8,
              itemWidth: 38,
              itemHeight: 46,
            ),
          ),
          const SizedBox(height: 20),
          PopEffect(
            trigger: _copyTrigger,
            animateOnDeactivate: true,
            peakScale: 1.15,
            child: GestureDetector(
              onTap: _copyCode,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.content_copy, size: 16, color: Colors.grey[700]),
                    const SizedBox(width: 6),
                    Text(
                      '복사',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[700],
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],
      ),
    );
  }

  Widget _buildFormActions() {
    return SizedBox(
      key: const ValueKey('form-actions'),
      child: Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: _isSaving ? null : () => Navigator.pop(context),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: const Text('취소'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: _isSaving ? null : _submit,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8)),
              ),
              child: _isSaving
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : const Text('초대'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCodeActions() {
    return SizedBox(
      key: const ValueKey('code-actions'),
      width: double.infinity,
      child: ElevatedButton(
        onPressed: () => Navigator.pop(context, {'inviteCode': _createdInviteCode}),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(vertical: 12),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        ),
        child: const Text('확인'),
      ),
    );
  }
}