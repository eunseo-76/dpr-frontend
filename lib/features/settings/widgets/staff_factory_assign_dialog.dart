import 'package:fprs_frontend/core/constants/api_constants.dart';
import 'package:fprs_frontend/core/models/master_data_entity.dart';
import 'package:fprs_frontend/core/services/master_data_service.dart';
import 'package:fprs_frontend/core/utils/toast.dart';
import 'package:fprs_frontend/core/utils/user_storage.dart';
import 'package:fprs_frontend/features/settings/services/invitation_service.dart';
import 'package:flutter/material.dart';

class StaffFactoryAssignDialog extends StatefulWidget {
  final List<int> userIds;

  const StaffFactoryAssignDialog({super.key, required this.userIds});

  @override
  State<StaffFactoryAssignDialog> createState() => _StaffFactoryAssignDialogState();
}

class _StaffFactoryAssignDialogState extends State<StaffFactoryAssignDialog> {
  final _service = InvitationService();

  List<MasterDataEntity> _factories = [];
  int? _selectedFactoryId;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _loadFactories();
  }

  Future<void> _loadFactories() async {
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
      _factories = factories;
      if (factories.isNotEmpty) _selectedFactoryId = factories.first.id;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    if (_selectedFactoryId == null) {
      showToast(context, '공장을 선택해주세요');
      return;
    }
    setState(() => _isSaving = true);
    try {
      await _service.assignFactory(
        userIds: widget.userIds,
        factoryId: _selectedFactoryId!,
      );
      if (mounted) Navigator.pop(context, true);
    } catch (e) {
      if (mounted) {
        showToast(context, e.toString().replaceFirst('Exception: ', ''));
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      backgroundColor: Colors.white,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 20),
      title: Text('${widget.userIds.length}명 공장 배치', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: _isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('공장', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
                const SizedBox(height: 6),
                DropdownButtonFormField<int>(
                  initialValue: _selectedFactoryId,
                  decoration: InputDecoration(
                    isDense: true,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                  items: _factories
                      .map((f) => DropdownMenuItem(value: f.id, child: Text(f.name)))
                      .toList(),
                  onChanged: (v) {
                    if (v != null) setState(() => _selectedFactoryId = v);
                  },
                ),
              ],
            ),
      actions: [
        TextButton(
          onPressed: _isSaving ? null : () => Navigator.pop(context),
          child: const Text('취소'),
        ),
        ElevatedButton(
          onPressed: _isSaving ? null : _submit,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.black87,
            foregroundColor: Colors.white,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          ),
          child: _isSaving
              ? const SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Text('배치'),
        ),
      ],
    );
  }
}
