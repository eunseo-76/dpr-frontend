import 'package:flutter/material.dart';

class DashedDivider extends StatelessWidget {
  const DashedDivider({super.key});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: LayoutBuilder(
        builder: (_, constraints) {
          final count = (constraints.maxWidth / 7).floor();
          return Row(
            children: List.generate(
              count,
              (_) => Container(
                width: 3,
                height: 1,
                margin: const EdgeInsets.only(right: 4),
                color: Colors.grey[400],
              ),
            ),
          );
        },
      ),
    );
  }
}
