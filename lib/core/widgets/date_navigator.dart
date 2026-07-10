import 'package:flutter/material.dart';

class DateNavigator extends StatelessWidget {
  final String label;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCalendarTap;

  const DateNavigator({
    super.key,
    required this.label,
    required this.onPrevious,
    required this.onNext,
    required this.onCalendarTap,
  });

  Widget _arrow(VoidCallback onTap, IconData icon) {
    return GestureDetector(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Icon(icon, size: 22, color: Colors.grey[500]),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _arrow(onPrevious, Icons.chevron_left_rounded),
        const SizedBox(width: 4),
        GestureDetector(
          onTap: onCalendarTap,
          child: Container(
            padding: const EdgeInsets.only(bottom: 3),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w500,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(width: 6),
                const Icon(Icons.calendar_today_outlined, size: 14, color: Colors.black87),
              ],
            ),
          ),
        ),
        const SizedBox(width: 4),
        _arrow(onNext, Icons.chevron_right_rounded),
      ],
    );
  }
}
