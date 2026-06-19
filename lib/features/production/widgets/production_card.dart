import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/core/widgets/section_card.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';

class ProductionCardFooter {
  final Map<int, double> dailyByUnit;
  final Map<int, double> cumulativeByUnit;

  ProductionCardFooter({
    required this.dailyByUnit,
    required this.cumulativeByUnit,
  });
}

class ProductionCard extends StatelessWidget {
  final String title;
  final Widget table;
  final List<Unit> units;
  final ProductionCardFooter? footer;
  final VoidCallback? onEditTap;

  const ProductionCard({
    super.key,
    required this.title,
    required this.table,
    required this.units,
    this.footer,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      onEditTap: onEditTap,
      footer: footer != null ? _buildFooter() : null,
      child: table,
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        _footerRow('합일실적', footer!.dailyByUnit),
        const SizedBox(height: 4),
        _footerRow('누적실적', footer!.cumulativeByUnit),
      ],
    );
  }

  Widget _footerRow(String label, Map<int, double> values) {
    final parts = units
        .where((u) => (values[u.id] ?? 0) != 0)
        .map((u) => '${u.name} ${formatNumber(values[u.id]!)}')
        .toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Text(
          parts.isEmpty ? '-' : parts.join('  '),
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}