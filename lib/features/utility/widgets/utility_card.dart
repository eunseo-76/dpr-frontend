import 'package:flutter/material.dart';
import 'package:fprs_frontend/core/utils/number_format.dart';
import 'package:fprs_frontend/core/widgets/section_card.dart';

// 전기&용수의 공장별/공정별 카드 - 제목 + 표(일/주/월/년에 따라 다름) + 누적합계 footer
class UtilityCard extends StatelessWidget {
  final String title;
  final Widget table;
  final double cumulativeElectricity;
  final double cumulativeWater;
  final VoidCallback? onEditTap;

  const UtilityCard({
    super.key,
    required this.title,
    required this.table,
    required this.cumulativeElectricity,
    required this.cumulativeWater,
    this.onEditTap,
  });

  @override
  Widget build(BuildContext context) {
    final electricityText = '${formatNumber(cumulativeElectricity)} Kwh';
    final waterText = '${formatNumber(cumulativeWater)} t';

    return SectionCard(
      title: title,
      onEditTap: onEditTap,
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