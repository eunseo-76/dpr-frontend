import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/features/production/utils/production_day_m2_grouping.dart';

class ProductionM2DayTable extends StatelessWidget {
  final List<ProductionM2DayRow> rows;

  const ProductionM2DayTable({super.key, required this.rows});

  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  static String _fmt(double? value) =>
      value == null || value == 0 ? '-' : formatNumber(value);

  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: _borderColor),
      columnWidths: const {
        0: FlexColumnWidth(2),
        1: FlexColumnWidth(2),
        2: FlexColumnWidth(2),
        3: FlexColumnWidth(2),
      },
      children: [
        TableRow(
          decoration: const BoxDecoration(color: _headerColor),
          children: const [
            _HeaderCell('업체'),
            _HeaderCell('공정'),
            _HeaderCell('실적(m2)'),
            _HeaderCell('재공(m2)'),
          ],
        ),
        for (final row in rows)
          TableRow(
            children: [
              _BodyCell(row.clientName),
              _BodyCell(row.processName),
              _BodyCell(_fmt(row.result)),
              _BodyCell(_fmt(row.wip)),
            ],
          ),
      ],
    );
  }
}

class _HeaderCell extends StatelessWidget {
  final String text;
  const _HeaderCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
      ),
    );
  }
}

class _BodyCell extends StatelessWidget {
  final String text;
  const _BodyCell(this.text);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 13),
      ),
    );
  }
}
