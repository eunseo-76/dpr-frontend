import 'package:flutter/material.dart';

class DateNavigation extends StatelessWidget {
  final String date;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onCalendarTap;

  const DateNavigation({
    super.key,
    required this.date,
    required this.onPrevious,
    required this.onNext,
    required this.onCalendarTap,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          icon: const Icon(Icons.chevron_left),
          onPressed: onPrevious,
        ),
        Text(date, style: const TextStyle(fontSize: 16)),
        IconButton(
          icon: const Icon(Icons.chevron_right),
          onPressed: onNext,
        ),
        IconButton(
          icon: const Icon(Icons.calendar_today),
          onPressed: onCalendarTap,
        ),
      ],
    );
  }
}
