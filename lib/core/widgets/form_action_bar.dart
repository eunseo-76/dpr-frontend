import 'package:flutter/material.dart';

class FormActionBar extends StatelessWidget {
  final bool hasChanges;
  final bool isLoading;
  final VoidCallback onSave;
  final String saveLabel;

  const FormActionBar({
    super.key,
    required this.hasChanges,
    required this.isLoading,
    required this.onSave,
    this.saveLabel = '저장',
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 48,
      child: ElevatedButton(
        onPressed: hasChanges && !isLoading ? onSave : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.black87,
          foregroundColor: Colors.white,
          disabledBackgroundColor: Colors.grey[300],
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          elevation: 0,
        ),
        child: isLoading
            ? const SizedBox(
                width: 20, height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: Colors.white,
                ),
              )
            : Text(
                saveLabel,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
      ),
    );
  }
}