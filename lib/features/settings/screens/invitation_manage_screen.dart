import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';
import 'package:dpr_frontend/core/widgets/name_avatar.dart';
import 'package:dpr_frontend/core/widgets/pin_code_field.dart';
import 'package:dpr_frontend/core/widgets/pop_effect.dart';
import 'package:dpr_frontend/core/widgets/rounded_checkbox.dart';
import 'package:dpr_frontend/core/widgets/pill_selector.dart';
import 'package:dpr_frontend/core/widgets/wrench_refresh.dart';
import 'package:flutter/services.dart';
import 'package:dpr_frontend/features/settings/models/invitation.dart';
import 'package:dpr_frontend/features/settings/models/user_member.dart';
import 'package:dpr_frontend/features/settings/services/invitation_service.dart';
import 'package:dpr_frontend/features/settings/widgets/invitation_create_dialog.dart';
import 'package:flutter/material.dart';

class InvitationManageScreen extends StatefulWidget {
  const InvitationManageScreen({super.key});

  @override
  State<InvitationManageScreen> createState() => _InvitationManageScreenState();
}

class _InvitationManageScreenState extends State<InvitationManageScreen> {
  final _service = InvitationService();
  List<UserMember> _users = [];
  List<Invitation> _pendingInvitations = [];
  bool _isLoading = true;
  int _filterIndex = 0;
  static const _filterLabels = ['전체', '공장별', '매니저만', '멤버만'];
  bool _isSelectionMode = false;
  final Set<int> _selectedUserIds = {};

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);
    try {
      final results = await Future.wait([
        _service.getUsers(),
        _service.getInvitations(),
      ]);
      if (!mounted) return;
      setState(() {
        _users = (results[0] as List<UserMember>)
            .where((u) => u.role != 'OWNER')
            .toList();
        final invitations = results[1] as List<Invitation>;
        _pendingInvitations = invitations.where((i) => i.isPending).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (mounted) {
        showToast(context, e.toString().replaceFirst('Exception: ', ''));
        setState(() => _isLoading = false);
      }
    }
  }

  String _roleLabel(String role) {
    return switch (role) {
      'OWNER' => '사장',
      'MANAGER' => '매니저',
      'STAFF' => '멤버',
      _ => role,
    };
  }

  void _enterSelectionMode(int userId) {
    setState(() {
      _isSelectionMode = true;
      _selectedUserIds.add(userId);
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedUserIds.clear();
    });
  }

  void _toggleSelection(int userId) {
    setState(() {
      if (_selectedUserIds.contains(userId)) {
        _selectedUserIds.remove(userId);
        if (_selectedUserIds.isEmpty) {
          _isSelectionMode = false;
        }
      } else {
        _selectedUserIds.add(userId);
      }
    });
  }

  Future<void> _confirmAndDeleteUsers() async {
    final count = _selectedUserIds.length;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('회원 삭제'),
        content: Text('선택한 $count명의 회원을 삭제하시겠습니까?\n삭제된 회원은 복구할 수 없습니다.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    try {
      await _service.deleteUsers(_selectedUserIds.toList());
      if (!mounted) return;
      showToast(context, '$count명의 회원이 삭제되었습니다', isError: false);
      _exitSelectionMode();
      _loadData();
    } catch (e) {
      if (!mounted) return;
      showToast(context, e.toString().replaceFirst('Exception: ', ''));
    }
  }

  String _remainingTime(String expiresAt) {
    final expires = DateTime.parse(expiresAt);
    final diff = expires.difference(DateTime.now());
    if (diff.isNegative) return '만료됨';
    if (diff.inHours >= 1) return '${diff.inHours}시간 후 만료';
    return '${diff.inMinutes}분 후 만료';
  }

  @override
  Widget build(BuildContext context) {
    Widget body;
    if (_isLoading) {
      body = const LoadingIndicator();
    } else {
      body = WrenchRefresh(
        onRefresh: _loadData,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            if (_pendingInvitations.isNotEmpty) ...[
              _sectionHeader('대기 중인 초대', _pendingInvitations.length),
              const SizedBox(height: 8),
              ..._pendingInvitations.map(_buildInvitationCard),
              const SizedBox(height: 24),
            ],
            _sectionHeader('가입된 회원', _users.length),
            const SizedBox(height: 8),
            PillSelector(
              labels: _filterLabels,
              selectedIndex: _filterIndex,
              onSelected: (i) => setState(() => _filterIndex = i),
              padding: const EdgeInsets.only(bottom: 12),
            ),
            if (_users.isEmpty)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(
                  child: Text('회원이 없습니다',
                      style: TextStyle(color: Colors.grey)),
                ),
              )
            else
              ..._buildFilteredUsers(),
          ],
        ),
      );
    }

    return PopScope(
      canPop: !_isSelectionMode,
      onPopInvokedWithResult: (didPop, _) {
        if (!didPop) _exitSelectionMode();
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        leading: _isSelectionMode
            ? IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              )
            : null,
        title: Text(
          _isSelectionMode
              ? '${_selectedUserIds.length}명 선택됨'
              : '초대 계정 관리',
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          if (_isSelectionMode)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: _confirmAndDeleteUsers,
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.delete_outline, size: 20, color: Colors.red[400]),
                ),
              ),
            )
          else
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: GestureDetector(
                onTap: () async {
                  final result = await showDialog<Map<String, dynamic>>(
                    context: context,
                    builder: (_) => const InvitationCreateDialog(),
                  );
                  if (result != null) {
                    if (!mounted) return;
                    showToast(context, '초대를 보냈습니다', isError: false);
                    _loadData();
                  }
                },
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    shape: BoxShape.circle,
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.1),
                        blurRadius: 6,
                        offset: const Offset(0, 2),
                      ),
                    ],
                  ),
                  child: Icon(Icons.add, size: 20, color: Colors.grey[700]),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          Container(
            height: MediaQuery.of(context).padding.top + kToolbarHeight,
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [Colors.white, Colors.grey[100]!],
              ),
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEFF0F4),
                border: Border(
                    top: BorderSide(color: Color(0xFFB0B8C8), width: 2)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment(0, -0.95),
                  colors: [Color(0xFFDFE4F0), Color(0xFFEFF0F4)],
                ),
              ),
              child: body,
            ),
          ),
        ],
      ),
    ),
    );
  }

  List<Widget> _buildFilteredUsers() {
    switch (_filterIndex) {
      case 1: // 공장별
        final grouped = <String, List<UserMember>>{};
        for (final u in _users) {
          final key = u.factoryName ?? '공장 미지정';
          grouped.putIfAbsent(key, () => []).add(u);
        }
        return grouped.entries.expand((e) => [
              Padding(
                padding: const EdgeInsets.only(top: 12, bottom: 8),
                child: Text(e.key,
                    style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.black54)),
              ),
              ...e.value.map(_buildUserCard),
            ]).toList();
      case 2: // 매니저
        final filtered = _users.where((u) => u.role == 'MANAGER').toList();
        if (filtered.isEmpty) {
          return [_emptyMessage('매니저가 없습니다')];
        }
        return filtered.map(_buildUserCard).toList();
      case 3: // 멤버
        final filtered = _users.where((u) => u.role == 'STAFF').toList();
        if (filtered.isEmpty) {
          return [_emptyMessage('멤버가 없습니다')];
        }
        return filtered.map(_buildUserCard).toList();
      default: // 전체
        return _users.map(_buildUserCard).toList();
    }
  }

  Widget _emptyMessage(String text) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Text(text, style: const TextStyle(color: Colors.grey)),
      ),
    );
  }

  Widget _sectionHeader(String title, int count) {
    return Row(
      children: [
        Text(
          title,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black87,
          ),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          decoration: BoxDecoration(
            color: Colors.grey[300],
            borderRadius: BorderRadius.circular(10),
          ),
          child: Text(
            '$count',
            style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
          ),
        ),
      ],
    );
  }

  void _showInviteCodeDialog(Invitation inv) {
    final controller = TextEditingController(text: inv.inviteCode);
    showDialog(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          bool copyTrigger = false;
          return AlertDialog(
            backgroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            insetPadding: const EdgeInsets.symmetric(horizontal: 20),
            title: const Text('초대코드', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  inv.email,
                  style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                ),
                const SizedBox(height: 20),
                IgnorePointer(
                  child: PinCodeField(
                    controller: controller,
                    autofocus: false,
                    gap: 8,
                    itemWidth: 38,
                    itemHeight: 46,
                  ),
                ),
                const SizedBox(height: 20),
                PopEffect(
                  trigger: copyTrigger,
                  animateOnDeactivate: true,
                  peakScale: 1.15,
                  child: GestureDetector(
                    onTap: () async {
                      setDialogState(() => copyTrigger = !copyTrigger);
                      await Clipboard.setData(ClipboardData(text: inv.inviteCode));
                      if (mounted) showToast(context, '초대코드가 복사되었습니다', isError: false);
                    },
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
                const SizedBox(height: 4),
              ],
            ),
            actions: [
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.black87,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  child: const Text('닫기'),
                ),
              ),
            ],
            actionsPadding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
          );
        },
      ),
    ).then((_) => controller.dispose());
  }

  Widget _buildInvitationCard(Invitation inv) {
    return GestureDetector(
      onTap: () => _showInviteCodeDialog(inv),
      child: Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  inv.email,
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: Colors.orange.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '대기중',
                  style:
                      TextStyle(fontSize: 11, color: Colors.orange.shade700),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _roleChip(inv.role),
              if (inv.factoryName != null) ...[
                const SizedBox(width: 6),
                _infoChip(inv.factoryName!),
              ],
              const Spacer(),
              Text(
                _remainingTime(inv.expiresAt),
                style: TextStyle(fontSize: 11, color: Colors.grey[500]),
              ),
            ],
          ),
        ],
      ),
      ),
    );
  }

  Widget _buildUserCard(UserMember user) {
    final isSelected = _selectedUserIds.contains(user.userId);

    return GestureDetector(
      onLongPress: () => _enterSelectionMode(user.userId),
      onTap: _isSelectionMode ? () => _toggleSelection(user.userId) : null,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isSelected ? Colors.blue.shade50 : Colors.white,
          borderRadius: BorderRadius.circular(12),
          border: isSelected
              ? Border.all(color: Colors.blue.shade200, width: 1.5)
              : null,
        ),
        child: Row(
          children: [
            if (_isSelectionMode) ...[
              RoundedCheckbox(
                value: isSelected,
                onChanged: (_) => _toggleSelection(user.userId),
              ),
              const SizedBox(width: 10),
            ],
            NameAvatar(name: user.name, size: 36, fontSize: 14),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    user.name,
                    style: const TextStyle(
                        fontSize: 14, fontWeight: FontWeight.w500),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    user.email,
                    style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                _roleChip(user.role),
                const SizedBox(height: 4),
                if (user.factoryName != null)
                  Text(
                    user.factoryName!,
                    style: TextStyle(fontSize: 11, color: Colors.grey[500]),
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _roleChip(String role) {
    final label = _roleLabel(role);
    final isManager = role == 'MANAGER';
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: isManager ? Colors.green.shade50 : Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 11,
          color: isManager ? Colors.green.shade700 : Colors.grey[700],
          fontWeight: isManager ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _infoChip(String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        text,
        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
      ),
    );
  }
}
