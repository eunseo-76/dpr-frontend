import 'package:flutter/material.dart';

class SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: options.map((option) {
        return Expanded(
          child: TextButton(
            onPressed: () => onChanged(option),
            style: TextButton.styleFrom(
              backgroundColor: option == selected ? Colors.blue : null,
            ),
            child: Text(option),
          ),
        );
      }).toList(),
    );
  }
}
