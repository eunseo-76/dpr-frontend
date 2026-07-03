import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/models/master_data_entity.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/widgets/rounded_checkbox.dart';
import 'package:dpr_frontend/features/settings/models/user_member.dart';
import 'package:dpr_frontend/features/settings/services/invitation_service.dart';
import 'package:flutter/material.dart';

class ManagerFactorySyncDialog extends StatefulWidget {
  final UserMember manager;

  const ManagerFactorySyncDialog({super.key, required this.manager});

  @override
  State<ManagerFactorySyncDialog> createState() => _ManagerFactorySyncDialogState();
}

class _ManagerFactorySyncDialogState extends State<ManagerFactorySyncDialog> {
  final _service = InvitationService();

  List<MasterDataEntity> _factories = [];
  late Set<int> _checkedIds;
  bool _isLoading = true;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _checkedIds = widget.manager.factories.map((f) => f.factoryId).toSet();
    _loadFactories();
  }

  Future<void> _loadFactories() async {
    final factories = await MasterDataService(
      endpoint: ApiConstants.factory_,
      idKey: 'factoryId',
    ).getAll();
    if (!mounted) return;
    setState(() {
      _factories = factories;
      _isLoading = false;
    });
  }

  Future<void> _submit() async {
    setState(() => _isSaving = true);
    try {
      await _service.syncManagerFactories(
        userId: widget.manager.userId,
        factoryIds: _checkedIds.toList(),
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
      title: Text('${widget.manager.name} 담당 공장 관리', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
      content: _isLoading
          ? const SizedBox(height: 100, child: Center(child: CircularProgressIndicator()))
          : SizedBox(
              width: double.maxFinite,
              child: SingleChildScrollView(
                child: Wrap(
                  spacing: 8,
                  runSpacing: 0,
                  children: _factories.map((f) {
                    final isChecked = _checkedIds.contains(f.id);
                    return SizedBox(
                      width: 160,
                      child: InkWell(
                        onTap: () => setState(() {
                          if (isChecked) {
                            _checkedIds.remove(f.id);
                          } else {
                            _checkedIds.add(f.id);
                          }
                        }),
                        borderRadius: BorderRadius.circular(8),
                        child: Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8),
                          child: Row(
                            children: [
                              RoundedCheckbox(value: isChecked),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Text(
                                  f.name,
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
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
              : const Text('저장'),
        ),
      ],
    );
  }
}
