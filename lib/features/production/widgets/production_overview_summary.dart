import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/label_store.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/core/widgets/dashed_divider.dart';
import 'package:dpr_frontend/features/production/utils/production_overview_grouping.dart';

class ProductionOverviewSummary extends StatelessWidget {
  final List<ProcessSummaryDisplayEntry> entries;

  const ProductionOverviewSummary({super.key, required this.entries});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          LabelStore.get('PRODUCTION_OVERVIEW_SUMMARY_TITLE', '공정별 실적 합계'),
          style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 6),
        for (int i = 0; i < entries.length; i++) ...[
          if (i > 0 && entries[i].isNewProcessGroup) const DashedDivider(),
          _row(entries[i]),
        ],
      ],
    );
  }

  Widget _row(ProcessSummaryDisplayEntry entry) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          Expanded(
            child: Text(
              entry.processName,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
          ),
          SizedBox(
            width: 90,
            child: Text.rich(
              TextSpan(children: [
                TextSpan(
                  text: formatNumber(entry.result),
                  style: const TextStyle(fontSize: 12),
                ),
                TextSpan(
                  text: ' ${entry.unitName}',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                ),
              ]),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
