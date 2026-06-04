import 'package:flutter/material.dart';

class PeriodSelector extends StatelessWidget {
  final String selectedPeriod;
  final ValueChanged<String> onPeriodChanged;

  const PeriodSelector({
    super.key,
    required this.selectedPeriod,
    required this.onPeriodChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Row(
        children: ['일', '주', '월', '년'].map((period) {
          final selected = selectedPeriod == period;
          return Expanded(
            child: TextButton(
              onPressed: () => onPeriodChanged(period),
              style: TextButton.styleFrom(
                backgroundColor: selected ? Colors.blue.shade100 : null,
              ),
              child: Text(period),
            ),
          );
        }).toList(),
      ),
    );
  }
}
