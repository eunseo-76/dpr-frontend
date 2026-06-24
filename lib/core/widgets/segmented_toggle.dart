import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/widgets/pop_effect.dart';

class SegmentedToggle extends StatelessWidget {
  final List<String> options;
  final String selected;
  final ValueChanged<String> onChanged;
  final Color activeColor;

  const SegmentedToggle({
    super.key,
    required this.options,
    required this.selected,
    required this.onChanged,
    this.activeColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.asMap().entries.map((entry) {
        final option = entry.value;
        final isLast = entry.key == options.length - 1;
        final isSelected = option == selected;
        return Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : 8),
          child: GestureDetector(
            onTap: () => onChanged(option),
            child: PopEffect(
              trigger: isSelected,
              peakScale: 1.15,
              duration: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                decoration: BoxDecoration(
                  color: isSelected
                      ? activeColor.withValues(alpha: 0.1)
                      : Colors.white,
                  border: Border.all(
                    color: isSelected
                        ? Colors.white.withValues(alpha: 0.6)
                        : Colors.grey[300]!,
                    width: 1.5,
                  ),
                  borderRadius: BorderRadius.circular(20),
                  boxShadow: [
                    BoxShadow(
                      color: isSelected
                          ? activeColor.withValues(alpha: 0.15)
                          : Colors.black.withValues(alpha: 0.08),
                      blurRadius: isSelected ? 8 : 6,
                      offset: const Offset(0, 2),
                    ),
                  ],
                ),
                child: Text(
                  option,
                  style: TextStyle(
                    color: isSelected ? activeColor : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }
}
