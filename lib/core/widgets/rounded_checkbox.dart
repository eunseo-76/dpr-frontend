import 'package:flutter/material.dart';
import 'package:fprs_frontend/core/widgets/pop_effect.dart';

// 체크박스 커스텀
class RoundedCheckbox extends StatelessWidget {
  final bool value;
  final ValueChanged<bool?>? onChanged;
  final double size;

  const RoundedCheckbox({
    super.key,
    required this.value,
    this.onChanged,
    this.size = 22,
  });

  @override
  Widget build(BuildContext context) {
    final outerRadius = BorderRadius.circular(size * 0.25);

    return GestureDetector(
      onTap: onChanged != null ? () => onChanged!(!value) : null,
      child: PopEffect(
        trigger: value,
        peakScale: 1.25,
        duration: const Duration(milliseconds: 300),
        animateOnDeactivate: true,
        child: value ? _buildChecked(outerRadius) : _buildUnchecked(outerRadius),
      ),
    );
  }

  Widget _buildChecked(BorderRadius radius) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        color: Colors.blue,
        borderRadius: radius,
      ),
      child: Icon(Icons.check_rounded, size: size * 0.75, color: Colors.white),
    );
  }

  Widget _buildUnchecked(BorderRadius outerRadius) {
    final innerRadius = BorderRadius.circular(size * 0.25 - 1.5);

    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        borderRadius: outerRadius,
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Colors.grey[600]!, Colors.grey[300]!],
        ),
      ),
      padding: const EdgeInsets.all(1.5),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: innerRadius,
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.center,
            colors: [Colors.grey[200]!, Colors.white],
            stops: const [0.0, 0.35],
          ),
        ),
      ),
    );
  }
}
