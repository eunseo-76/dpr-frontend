import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/widgets/pop_effect.dart';

class SegmentedToggle extends StatelessWidget {
  final List<String> options; // 화면에 그릴 글자 (DB 라벨이 바뀔 수 있음)
  final List<String>?
      values; // 탭했을 때 실제로 돌려줄 값. null이면 options를 그대로 값으로 씀(기존 동작 그대로 유지)
  final String selected; // values[i] (values가 없으면 options[i])와 비교됨
  final ValueChanged<String> onChanged;
  final Color activeColor;

  const SegmentedToggle({
    super.key,
    required this.options,
    this.values,
    required this.selected,
    required this.onChanged,
    this.activeColor = Colors.blue,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveValues = values ?? options;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: options.asMap().entries.map((entry) {
        final index = entry.key;
        final label = entry.value;
        final value = effectiveValues[index];
        final isLast = index == options.length - 1;
        final isSelected = value == selected;
        return Padding(
          padding: EdgeInsets.only(right: isLast ? 0 : 7),
          child: GestureDetector(
            onTap: () => onChanged(value),
            child: PopEffect(
              trigger: isSelected,
              peakScale: 1.15,
              duration: const Duration(milliseconds: 400),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
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
                  label,
                  style: TextStyle(
                    color: isSelected ? activeColor : Colors.black87,
                    fontWeight: FontWeight.w600,
                    fontSize: 11,
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
