import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/core/widgets/dashed_divider.dart';
import 'package:dpr_frontend/features/production/utils/production_overview_grouping.dart';

class ProductionOverviewSummary extends StatelessWidget {
  final List<ProcessSummaryDisplayEntry> entries;
  final bool showAmount;

  const ProductionOverviewSummary({
    super.key,
    required this.entries,
    required this.showAmount,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        for (int i = 0; i < entries.length; i++) ...[
          if (i > 0) const DashedDivider(),
          _row(entries[i]),
        ],
      ],
    );
  }

  Widget _row(ProcessSummaryDisplayEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 48,
            child: Text(
              entry.processName,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          Expanded(
            child: Wrap(
              alignment: WrapAlignment.end,
              crossAxisAlignment: WrapCrossAlignment.center,
              spacing: 8,
              runSpacing: 4,
              children: [
                for (final u in entry.unitResults)
                  Text.rich(TextSpan(children: [
                    TextSpan(
                      text: formatNumber(u.result),
                      style: const TextStyle(fontSize: 12),
                    ),
                    TextSpan(
                      text: ' ${u.unitName}',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                    ),
                  ])),
                if (showAmount)
                  entry.totalAmount == null
                      ? Text(
                          '-',
                          style: TextStyle(fontSize: 12, color: Colors.grey[500]),
                        )
                      : Text.rich(TextSpan(children: [
                          TextSpan(
                            text: formatManwon(entry.totalAmount),
                            style: const TextStyle(fontSize: 12),
                          ),
                          const TextSpan(
                            text: ' 만원',
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                          ),
                        ])),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
