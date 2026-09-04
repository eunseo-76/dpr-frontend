import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:fprs_frontend/features/production_comparison/models/process_metric_row.dart';
import 'package:fprs_frontend/features/production_comparison/utils/comparison_diff.dart';

typedef _MetricValues = (double? a, double? b);

class ProcessComparisonTable extends StatelessWidget {
  final List<ProcessMetricRow> rows;
  final bool showWip;
  final String unitLabel;
  final String dateALabel;
  final String dateBLabel;

  const ProcessComparisonTable({
    super.key,
    required this.rows,
    required this.showWip,
    required this.unitLabel,
    required this.dateALabel,
    required this.dateBLabel,
  });

  static const _colProcess = 72.0;
  static const _valueColWidth = 56.0;
  static const _rowHeight = 36.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);
  static const _upColor = Color(0xFF0CA30C);
  static const _downColor = Color(0xFFD03B3B);

  List<(String label, _MetricValues Function(ProcessMetricRow))> get _metricGroups => [
    ('실적($unitLabel)', (r) => (r.resultA, r.resultB)),
    if (showWip) ('재공($unitLabel)', (r) => (r.wipA, r.wipB)),
    ('금액(만원)', (r) => (r.amountA, r.amountB)),
  ];

  int get _columnCount => 1 + _metricGroups.length * 3;
  int get _rowCount => 2 + rows.length;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowCount * _rowHeight,
      child: TableView.builder(
        columnCount: _columnCount,
        rowCount: _rowCount,
        pinnedColumnCount: 1,
        verticalDetails: const ScrollableDetails.vertical(
          physics: NeverScrollableScrollPhysics(),
        ),
        horizontalDetails: const ScrollableDetails.horizontal(
          physics: ClampingScrollPhysics(),
        ),
        columnBuilder: (column) => TableSpan(
          extent: FixedTableSpanExtent(column == 0 ? _colProcess : _valueColWidth),
          foregroundDecoration: const TableSpanDecoration(
            border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
          ),
        ),
        rowBuilder: (row) => TableSpan(
          extent: const FixedTableSpanExtent(_rowHeight),
          backgroundDecoration: row < 2 ? const TableSpanDecoration(color: _headerColor) : null,
          foregroundDecoration: const TableSpanDecoration(
            border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
          ),
        ),
        cellBuilder: _buildCell,
      ),
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    if (vicinity.column == 0) {
      if (vicinity.row < 2) {
        return TableViewCell(
          rowMergeStart: 0,
          rowMergeSpan: 2,
          child: _cell('공정', isHeader: true),
        );
      }
      return TableViewCell(child: _cell(rows[vicinity.row - 2].processName));
    }

    if (vicinity.row < 2) return _buildHeaderCell(vicinity);

    return TableViewCell(child: _buildDataCell(rows[vicinity.row - 2], vicinity.column));
  }

  TableViewCell _buildHeaderCell(TableVicinity vicinity) {
    final groupIndex = (vicinity.column - 1) ~/ 3;
    final groupStartCol = 1 + groupIndex * 3;
    final subIndex = (vicinity.column - 1) % 3;

    if (vicinity.row == 0) {
      return TableViewCell(
        columnMergeStart: groupStartCol,
        columnMergeSpan: 3,
        child: _cell(_metricGroups[groupIndex].$1, isHeader: true),
      );
    }

    final label = switch (subIndex) {
      0 => dateALabel,
      1 => dateBLabel,
      _ => '증감',
    };
    return TableViewCell(child: _cell(label, isHeader: true));
  }

  Widget _buildDataCell(ProcessMetricRow row, int column) {
    final groupIndex = (column - 1) ~/ 3;
    final subIndex = (column - 1) % 3;
    final (a, b) = _metricGroups[groupIndex].$2(row);

    if (subIndex == 0) return _cell(_formatValue(a));
    if (subIndex == 1) return _cell(_formatValue(b));

    final diff = computeDiff(a, b);
    return _cell(
      diff.label,
      color: switch (diff.direction) {
        ComparisonDirection.up => _upColor,
        ComparisonDirection.down => _downColor,
        _ => null,
      },
    );
  }

  String _formatValue(double? value) => value == null ? '-' : value.toStringAsFixed(1);

  Widget _cell(String text, {bool isHeader = false, Color? color}) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }
}
