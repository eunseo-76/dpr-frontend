import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/core/widgets/section_card.dart';

// 전기&용수의 공장별/공정별 카드 - 제목 + 표(일/주/월/년에 따라 다름) + 누적합계 footer
class UtilityCard extends StatelessWidget {
  final String title;
  final Widget table;

  // TODO: 누적 합계 아직 없음... 일단 null
  final double? cumulativeElectricity;
  final double? cumulativeWater;

  const UtilityCard({
    super.key,
    required this.title,
    required this.table,
    this.cumulativeElectricity,
    this.cumulativeWater,
  });

  @override
  Widget build(BuildContext context) {
    final electricityText = cumulativeElectricity == null
        ? '준비중'
        : '${formatNumber(cumulativeElectricity!)} Kwh';
    final waterText = cumulativeWater == null
        ? '준비중'
        : '${formatNumber(cumulativeWater!)} t';

    return SectionCard(
      title: title,
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
      child: table,
    );
  }
}