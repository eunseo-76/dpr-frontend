import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/core/widgets/section_card.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';

class ProductionCardFooter {
  final Map<int, double> dailyByUnit;
  final Map<int, double> cumulativeByUnit;
  final Map<int, double> amountByUnit;

  ProductionCardFooter({
    required this.dailyByUnit,
    required this.cumulativeByUnit,
    required this.amountByUnit,
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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (footer != null) ...[
            _buildFooter(),
            const SizedBox(height: 12),
          ],
          table,
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        _footerRow('기간별 합계 실적', footer!.dailyByUnit),
        _receiptDivider(),
        _footerRow('누적실적', footer!.cumulativeByUnit),
        _receiptDivider(),
        _footerAmountRow('총 금액', footer!.amountByUnit),
      ],
    );
  }

  Widget _receiptDivider() {
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

  Widget _footerRow(String label, Map<int, double> values) {
    final entries = units.where((u) => (values[u.id] ?? 0) != 0).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        if (entries.isEmpty)
          const Text('-', style: TextStyle(fontSize: 12))
        else
          Row(
            children: entries.map((u) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Text.rich(TextSpan(children: [
                TextSpan(text: u.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                TextSpan(text: ' ${formatNumber(values[u.id]!)}', style: const TextStyle(fontSize: 12)),
              ])),
            )).toList(),
          ),
      ],
    );
  }

  Widget _footerAmountRow(String label, Map<int, double> values) {
    final entries = units.where((u) => (values[u.id] ?? 0) != 0).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        entries.isEmpty
            ? const Text('-', style: TextStyle(fontSize: 12))
            : Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: entries.map((u) => Text.rich(TextSpan(children: [
                  TextSpan(text: u.name, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  TextSpan(text: '  ₩${formatNumber(values[u.id]!)}', style: const TextStyle(fontSize: 12)),
                ]))).toList(),
              ),
      ],
    );
  }
}