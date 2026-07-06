import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/widgets/pop_effect.dart';

class PillSelector extends StatelessWidget {
  final List<String> labels;
  final int selectedIndex;
  final ValueChanged<int> onSelected;
  final EdgeInsetsGeometry padding;

  const PillSelector({
    super.key,
    required this.labels,
    required this.selectedIndex,
    required this.onSelected,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
  });

  ({BoxDecoration decoration, TextStyle textStyle}) _pillStyle(bool isSelected) {
    return (
      decoration: BoxDecoration(
        color: isSelected
            ? Colors.blue.withValues(alpha: 0.1)
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
                ? Colors.blue.withValues(alpha: 0.15)
                : Colors.black.withValues(alpha: 0.08),
            blurRadius: isSelected ? 8 : 6,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      textStyle: TextStyle(
        color: isSelected ? Colors.blue : Colors.black87,
        fontWeight: FontWeight.w600,
        fontSize: 13,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      padding: padding,
      child: Row(
        children: labels.asMap().entries.map((entry) {
          final isSelected = entry.key == selectedIndex;
          final style = _pillStyle(isSelected);
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: GestureDetector(
              onTap: () => onSelected(entry.key),
              child: PopEffect(
                trigger: isSelected,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: style.decoration,
                  child: Text(entry.value, style: style.textStyle),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }
}
