import 'package:flutter/material.dart';

class DateRangeRow extends StatelessWidget {
  static const dateAColor = Colors.blue;
  static const dateBColor = Colors.green;

  final String startLabel;
  final String endLabel;
  final VoidCallback onTapStart;
  final VoidCallback onTapEnd;
  final Color startDotColor;
  final Color endDotColor;
  final Widget separator;

  const DateRangeRow({
    super.key,
    required this.startLabel,
    required this.endLabel,
    required this.onTapStart,
    required this.onTapEnd,
    this.startDotColor = dateAColor,
    this.endDotColor = dateBColor,
    this.separator = const Icon(Icons.compare_arrows_rounded, size: 16, color: Color(0xFF9E9E9E)),
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _dateChip(startLabel, startDotColor, onTapStart)),
        const SizedBox(width: 8),
        separator,
        const SizedBox(width: 8),
        Expanded(child: _dateChip(endLabel, endDotColor, onTapEnd)),
      ],
    );
  }

  Widget _dateChip(String label, Color dotColor, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 7,
                  height: 7,
                  decoration: BoxDecoration(color: dotColor, shape: BoxShape.circle),
                ),
                const SizedBox(width: 6),
                Text(
                  label,
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w700),
                ),
              ],
            ),
            Icon(Icons.calendar_today_outlined, size: 13, color: Colors.grey[500]),
          ],
        ),
      ),
    );
  }
}
