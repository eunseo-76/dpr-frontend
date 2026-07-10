import 'package:flutter/material.dart';

class FactoryTag extends StatelessWidget {
  final String label;

  const FactoryTag({super.key, required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: Colors.grey[300],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white, width: 1),
      ),
      child: Text(
        label,
        style: TextStyle(fontSize: 11, color: Colors.grey[700]),
      ),
    );
  }
}
