import 'package:dpr_frontend/core/widgets/confirm_dialog.dart';
import 'package:dpr_frontend/core/widgets/form_action_bar.dart';
import 'package:flutter/material.dart';

class FormDialog extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget content;
  final bool hasChanges;
  final bool isLoading;
  final VoidCallback onSave;
  final String saveLabel;

  const FormDialog({
    super.key,
    required this.title,
    this.subtitle,
    required this.content,
    required this.hasChanges,
    required this.isLoading,
    required this.onSave,
    this.saveLabel = '저장',
  });

  Future<bool> _confirmDismiss(BuildContext context) async {
    if (!hasChanges) return true;
    return showConfirmDialog(
      context,
      title: '변경사항이 있습니다',
      content: '저장하지 않고 나가시겠습니까?',
      confirmLabel: '나가기',
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDismiss(context);
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 40),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(title, style: const TextStyle(fontSize: 17, fontWeight: FontWeight.w600)),
            if (subtitle != null) ...[
              const SizedBox(height: 4),
              Text(
                subtitle!,
                style: TextStyle(fontSize: 12, color: Colors.grey[500]),
              ),
            ],
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(48, 16, 48, 16),
        content: SizedBox(
          width: double.maxFinite,
          child: content,
        ),
        actionsPadding: const EdgeInsets.fromLTRB(24, 0, 24, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: isLoading ? null : () async {
                      final shouldPop = await _confirmDismiss(context);
                      if (shouldPop && context.mounted) Navigator.pop(context);
                    },
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.black87,
                      side: BorderSide(color: Colors.grey[300]!),
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
                    ),
                    child: const Text('취소', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FormActionBar(
                  hasChanges: hasChanges,
                  isLoading: isLoading,
                  onSave: onSave,
                  saveLabel: saveLabel,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}