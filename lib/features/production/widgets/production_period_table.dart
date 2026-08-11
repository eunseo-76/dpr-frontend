import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:fprs_frontend/core/utils/label_store.dart';
import 'package:fprs_frontend/core/utils/number_format.dart';
import 'package:fprs_frontend/features/production/utils/production_period_grouping.dart';

class ProductionPeriodTable extends StatelessWidget {
  final String rowLabelHeader;
  final List<String> columnLabels;
  final List<ProductionPeriodRow> rows;
  final List<String?>? columnTooltips;
  final List<String>? columnDates;
  final void Function(String date)? onDateTap;

  const ProductionPeriodTable({
    super.key,
    required this.rowLabelHeader,
    required this.columnLabels,
    required this.rows,
    this.columnTooltips,
    this.columnDates,
    this.onDateTap,
  });

  static const _colLabelWidth = 48.0;
  static const _colShiftWidth = 26.0;
  static const _colUnitWidth = 34.0;
  static const _periodColWidth = 42.0;
  static const _fixedColWidth = 46.0;
  static const _rowHeight = 36.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  int get _columnCount => 3 + columnLabels.length;
  int get _rowCount => 1 + rows.length;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _rowCount * _rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TableView.builder(
              columnCount: _columnCount,
              rowCount: _rowCount,
              pinnedColumnCount: 3,
              verticalDetails: const ScrollableDetails.vertical(
                physics: NeverScrollableScrollPhysics(),
              ),
              horizontalDetails: const ScrollableDetails.horizontal(
                physics: ClampingScrollPhysics(),
              ),
              columnBuilder: _buildColumnSpan,
              rowBuilder: _buildRowSpan,
              cellBuilder: (context, vicinity) {
                final merge = _cellMerge(vicinity);
                return TableViewCell(
                  rowMergeStart: merge?.$1,
                  rowMergeSpan: merge?.$2,
                  child: _buildCell(vicinity),
                );
              },
            ),
          ),
          _buildFixedRight(),
        ],
      ),
    );
  }

  TableSpan _buildColumnSpan(int column) {
    final double width;
    if (column == 0) {
      width = _colLabelWidth;
    } else if (column == 1) {
      width = _colShiftWidth;
    } else if (column == 2) {
      width = _colUnitWidth;
    } else {
      width = _periodColWidth;
    }
    return TableSpan(
      extent: FixedTableSpanExtent(width),
      foregroundDecoration: const TableSpanDecoration(
        border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
      ),
    );
  }

  TableSpan _buildRowSpan(int row) {
    return TableSpan(
      extent: const FixedTableSpanExtent(_rowHeight),
      backgroundDecoration: row == 0
          ? const TableSpanDecoration(color: _headerColor)
          : null,
      foregroundDecoration: const TableSpanDecoration(
        border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
      ),
    );
  }

  (int, int)? _cellMerge(TableVicinity vicinity) {
    if (vicinity.row == 0) return null;
    final row = rows[vicinity.row - 1];

    if (vicinity.column == 0) {
      final start = rows.indexWhere((r) => r.rowGroupId == row.rowGroupId);
      final span = rows.where((r) => r.rowGroupId == row.rowGroupId).length;
      return (start + 1, span);
    }
    if (vicinity.column == 1) {
      final start = rows.indexWhere(
          (r) => r.rowGroupId == row.rowGroupId && r.shift == row.shift);
      final span = rows
          .where(
              (r) => r.rowGroupId == row.rowGroupId && r.shift == row.shift)
          .length;
      return (start + 1, span);
    }
    return null;
  }

  Widget _buildCell(TableVicinity vicinity) {
    final isHeader = vicinity.row == 0;
    final column = vicinity.column;

    if (isHeader) {
      if (column == 0) return _styledCell(rowLabelHeader, isHeader: true);
      if (column == 1) {
        return _styledCell(LabelStore.get('PRODUCTION_TABLE_HEADER_TYPE', '구분'), isHeader: true);
      }
      if (column == 2) {
        return _styledCell(LabelStore.get('PRODUCTION_TABLE_HEADER_UNIT', '단위'), isHeader: true);
      }
      final dateIndex = column - 3;
      final label = columnLabels[dateIndex];
      final tip = columnTooltips != null ? columnTooltips![dateIndex] : null;

      Widget cell;
      if (columnDates != null && onDateTap != null) {
        cell = InkWell(
          onTap: () => onDateTap!(columnDates![dateIndex]),
          child: _styledCell(label, isHeader: true, color: Colors.blue),
        );
      } else {
        cell = _styledCell(label, isHeader: true);
      }

      if (tip != null) {
        return Tooltip(
          message: tip,
          preferBelow: false,
          triggerMode: TooltipTriggerMode.tap,
          child: cell,
        );
      }
      return cell;
    }

    final row = rows[vicinity.row - 1];
    if (column == 0) return _styledCell(row.rowGroupName, wrap: true);
    if (column == 1) return _styledCell(row.shift);
    if (column == 2) return _styledCell(row.unitName);
    final value = row.values[column - 3];
    if (row.unitName == '금액') {
      return _styledCell(formatManwon(value));
    }
    if (value != null && value != 0 && value.abs() >= 10000) {
      return _compactCell(value);
    }
    return _styledCell(_fmt(value));
  }

  Widget _buildFixedRight() {
    return Container(
      width: _fixedColWidth,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _borderColor)),
      ),
      child: Column(
        children: List.generate(_rowCount, (i) {
          final isHeader = i == 0;
          if (isHeader) {
            return _fixedCell(LabelStore.get('PRODUCTION_TABLE_HEADER_SUM', '실적 합계'), isHeader: true);
          }
          final row = rows[i - 1];
          if (row.unitName == '금액') {
            return _fixedCell(formatManwon(row.total));
          }
          if (row.total != 0 && row.total.abs() >= 10000) {
            return _fixedCompactCell(row.total);
          }
          return _fixedCell(_fmt(row.total));
        }),
      ),
    );
  }

  Widget _fixedCell(String text, {bool isHeader = false}) {
    return Container(
      height: _rowHeight,
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      decoration: BoxDecoration(
        color: isHeader ? _headerColor : null,
        border: const Border(bottom: BorderSide(color: _borderColor)),
      ),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 12,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  Widget _fixedCompactCell(double value) {
    return Tooltip(
      message: formatNumber(value),
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        height: _rowHeight,
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 4),
        decoration: const BoxDecoration(
          border: Border(bottom: BorderSide(color: _borderColor)),
        ),
        child: Text(
          formatCompact(value),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _styledCell(String text, {
    bool isHeader = false,
    Color? color,
    bool wrap = false,
  }) {
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Text(
        text,
        textAlign: TextAlign.center,
        overflow: wrap ? null : TextOverflow.ellipsis,
        maxLines: wrap ? null : 1,
        style: TextStyle(
          fontSize: 11,
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
          color: color,
        ),
      ),
    );
  }

  Widget _compactCell(double value) {
    return Tooltip(
      message: formatNumber(value),
      preferBelow: false,
      triggerMode: TooltipTriggerMode.tap,
      child: Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 2),
        child: Text(
          formatCompact(value),
          textAlign: TextAlign.center,
          overflow: TextOverflow.ellipsis,
          maxLines: 1,
          style: const TextStyle(fontSize: 11),
        ),
      ),
    );
  }

  String _fmt(double? v) =>
      v == null || v == 0 ? '-' : formatNumber(v);
}