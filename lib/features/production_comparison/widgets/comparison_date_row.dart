import 'package:flutter/material.dart';

class ComparisonDateRow extends StatelessWidget {
  static const dateAColor = Colors.blue;
  static const dateBColor = Colors.green;

  final String dateALabel;
  final String dateBLabel;
  final VoidCallback onTapDateA;
  final VoidCallback onTapDateB;

  const ComparisonDateRow({
    super.key,
    required this.dateALabel,
    required this.dateBLabel,
    required this.onTapDateA,
    required this.onTapDateB,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(child: _dateChip(dateALabel, dateAColor, onTapDateA)),
        const SizedBox(width: 8),
        Icon(Icons.compare_arrows_rounded, size: 16, color: Colors.grey[500]),
        const SizedBox(width: 8),
        Expanded(child: _dateChip(dateBLabel, dateBColor, onTapDateB)),
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
