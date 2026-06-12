import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/core/widgets/section_card.dart';
import 'package:dpr_frontend/core/widgets/simple_data_table.dart';
import 'package:dpr_frontend/features/utility/utils/utility_grouping.dart';

// 전기&용수의 공장별/공정별 카드
class UtilityCard extends StatelessWidget {
  final UtilityGroup group;

  // TODO: 누적 합계 아직 없음... 일단 null
  final double? cumulativeElectricity;
  final double? cumulativeWater;

  const UtilityCard({
    super.key,
    required this.group,
    this.cumulativeElectricity,
    this.cumulativeWater,
  });

  @override
  Widget build(BuildContext context) {

    final headers = <String>['구분', '전기(Kwh)', '용수(t)'];
    final rows = group.rows
        .map((r) => [r.label, formatNumber(r.electricity), formatNumber(r.water)])
        .toList();

    final electricityText = cumulativeElectricity == null
        ? '준비중'
        : '${formatNumber(cumulativeElectricity!)} Kwh';
    final waterText = cumulativeWater == null
        ? '준비중'
        : '${formatNumber(cumulativeWater!)} t';

    return SectionCard(
      title: group.groupName,
      footer: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          const Text('누적합계'),
          Row(
            children: [
              Text('전기 $electricityText'),
              const SizedBox(width: 16),
              Text('용수 $waterText'),
            ],
          ),
        ],
      ),
      child: SimpleDataTable(headers: headers, rows: rows),
    );
  }
}