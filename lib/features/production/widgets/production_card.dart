import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/label_store.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/core/widgets/dashed_divider.dart';
import 'package:dpr_frontend/core/widgets/section_card.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';

class ProductionCardFooter {
  final Map<int, double> dailyByUnit;
  final Map<int, double> cumulativeByUnit;
  final Map<int, double>? amountByUnit;
  final Map<int, double>? cumulativeAmountByUnit;

  ProductionCardFooter({
    required this.dailyByUnit,
    required this.cumulativeByUnit,
    this.amountByUnit,
    this.cumulativeAmountByUnit,
  });
}

class ProductionCard extends StatelessWidget {
  final String title;
  final Widget table;
  final List<Unit> units;
  final ProductionCardFooter? footer;
  final VoidCallback? onEditTap;
  final bool wrapInCard;

  const ProductionCard({
    super.key,
    required this.title,
    required this.table,
    required this.units,
    this.footer,
    this.onEditTap,
    this.wrapInCard = true,
  });

  @override
  Widget build(BuildContext context) {
    return SectionCard(
      title: title,
      onEditTap: onEditTap,
      wrapInCard: wrapInCard,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (footer != null) ...[
            _buildFooter(),
            const SizedBox(height: 12),
          ],
          Align(
            alignment: Alignment.centerRight,
            child: Text(
              LabelStore.get('PRODUCTION_TABLE_AMOUNT_UNIT_HINT', '금액 단위: 만'),
              style: TextStyle(fontSize: 11, color: Colors.grey[700]),
            ),
          ),
          const SizedBox(height: 4),
          table,
        ],
      ),
    );
  }

  Widget _buildFooter() {
    return Column(
      children: [
        _footerRow(
          LabelStore.get('PRODUCTION_SUMMARY_PERIOD_SUM', '기간별 실적 합계'),
          footer!.dailyByUnit,
          amounts: footer!.amountByUnit,
        ),
        const DashedDivider(),
        _footerRow(
          LabelStore.get('PRODUCTION_SUMMARY_CUMULATIVE_SUM', '누적 실적 합계'),
          footer!.cumulativeByUnit,
          amounts: footer!.cumulativeAmountByUnit,
        ),
      ],
    );
  }

  Widget _footerRow(String label, Map<int, double> values, {Map<int, double>? amounts}) {
    final entries = units.where((u) => (values[u.id] ?? 0) != 0).toList();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        if (entries.isEmpty)
          const Text('-', style: TextStyle(fontSize: 12))
        else
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: entries.map((u) => Padding(
              padding: const EdgeInsets.only(left: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text.rich(TextSpan(children: [
                    TextSpan(text: formatNumber(values[u.id]!), style: const TextStyle(fontSize: 12)),
                    TextSpan(text: ' ${u.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                  ])),
                  if (amounts != null)
                    Text.rich(TextSpan(children: [
                      TextSpan(text: formatManwon(amounts[u.id]), style: const TextStyle(fontSize: 12)),
                      const TextSpan(text: ' 원', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ])),
                ],
              ),
            )).toList(),
          ),
      ],
    );
  }
}