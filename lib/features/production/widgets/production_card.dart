import 'package:flutter/material.dart';
import 'package:fprs_frontend/core/utils/label_store.dart';
import 'package:fprs_frontend/core/utils/number_format.dart';
import 'package:fprs_frontend/core/widgets/dashed_divider.dart';
import 'package:fprs_frontend/core/widgets/section_card.dart';
import 'package:fprs_frontend/features/unit/models/unit.dart';

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
  final bool sumAmounts;

  const ProductionCard({
    super.key,
    required this.title,
    required this.table,
    required this.units,
    this.footer,
    this.onEditTap,
    this.wrapInCard = true,
    this.sumAmounts = false,
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

  // 공정별 뷰: 단위 하나만 잡히는 게 정상이라 첫 값만 사용 (여러 개면 데이터 이상)
  // 업체별 뷰: 공정마다 기준단위가 다를 수 있어 여러 금액이 동시에 잡히는 게 정상이라 합산
  double? _extractAmount(Map<int, double>? amounts) {
    if (amounts == null) return null;
    final nonZero = amounts.values.where((v) => v != 0);
    if (nonZero.isEmpty) return null;
    return sumAmounts ? nonZero.reduce((a, b) => a + b) : nonZero.first;
  }

  Widget _footerRow(String label, Map<int, double> values, {Map<int, double>? amounts}) {
    final entries = units.where((u) => (values[u.id] ?? 0) != 0).toList();
    final amount = _extractAmount(amounts);
    final showAmount = amounts != null;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(fontSize: 12)),
        Expanded(
          child: (entries.isEmpty && amount == null)
              ? const Align(
                  alignment: Alignment.centerRight,
                  child: Text('-', style: TextStyle(fontSize: 12)),
                )
              : Wrap(
                  alignment: WrapAlignment.end,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    ...entries.map((u) => Text.rich(TextSpan(children: [
                      TextSpan(text: formatNumber(values[u.id]!), style: const TextStyle(fontSize: 12)),
                      TextSpan(text: ' ${u.name}', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                    ]))),
                    if (showAmount)
                      Text.rich(TextSpan(children: [
                        TextSpan(text: formatManwon(amount), style: const TextStyle(fontSize: 12)),
                        const TextSpan(text: ' 만원', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      ])),
                  ],
                ),
        ),
      ],
    );
  }
}