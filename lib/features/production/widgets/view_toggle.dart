import 'package:flutter/material.dart';

class ViewToggle extends StatelessWidget {
  final bool isProcessView;
  final ValueChanged<bool> onChanged;

  const ViewToggle({
    super.key,
    required this.isProcessView,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: [
          FilledButton(
            onPressed: () => onChanged(true),
            style: isProcessView
                ? null
                : FilledButton.styleFrom(backgroundColor: Colors.grey),
            child: const Text('공정별 보기'),
          ),
          const SizedBox(width: 8),
          FilledButton(
            onPressed: () => onChanged(false),
            style: isProcessView
                ? FilledButton.styleFrom(backgroundColor: Colors.grey)
                : null,
            child: const Text('업체별 보기'),
          ),
        ],
      ),
    );
  }
}
