import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:dpr_frontend/core/utils/label_store.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/features/production/utils/production_overview_grouping.dart';

class ProductionOverviewTable extends StatelessWidget {
  final List<OverviewTableRow> rows;

  const ProductionOverviewTable({super.key, required this.rows});

  static const _minUnitWidth = 40.0;
  static const _minValueWidth = 56.0;
  static const _rowHeight = 36.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  int get _columnCount => 4;
  int get _rowCount => 1 + rows.length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final unitW = (constraints.maxWidth * 0.15).clamp(_minUnitWidth, 80.0);
        final valueW = (constraints.maxWidth * 0.25).clamp(_minValueWidth, 100.0);
        final remaining = constraints.maxWidth - unitW - valueW;
        final clientW = remaining / 2;
        final processW = remaining / 2;

        return SizedBox(
          height: _rowCount * _rowHeight,
          child: TableView.builder(
            columnCount: _columnCount,
            rowCount: _rowCount,
            pinnedColumnCount: 0,
            verticalDetails: const ScrollableDetails.vertical(
              physics: NeverScrollableScrollPhysics(),
            ),
            horizontalDetails: const ScrollableDetails.horizontal(
              physics: ClampingScrollPhysics(),
            ),
            columnBuilder: (column) =>
                _buildColumnSpan(column, clientW, processW, unitW, valueW),
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
        );
      },
    );
  }

  TableSpan _buildColumnSpan(
    int column,
    double clientW,
    double processW,
    double unitW,
    double valueW,
  ) {
    final width = switch (column) {
      0 => clientW,
      1 => processW,
      2 => unitW,
      _ => valueW,
    };
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
      backgroundDecoration:
          row == 0 ? const TableSpanDecoration(color: _headerColor) : null,
      foregroundDecoration: const TableSpanDecoration(
        border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
      ),
    );
  }

  // 업체(0번 열)만 연속된 같은 그룹끼리 병합
  (int, int)? _cellMerge(TableVicinity vicinity) {
    if (vicinity.row == 0 || vicinity.column != 0) return null;
    final groupIndex = rows[vicinity.row - 1].clientGroupIndex;
    final start = rows.indexWhere((r) => r.clientGroupIndex == groupIndex);
    final span = rows.where((r) => r.clientGroupIndex == groupIndex).length;
    return (start + 1, span);
  }

  Widget _buildCell(TableVicinity vicinity) {
    final isHeader = vicinity.row == 0;
    final column = vicinity.column;

    if (isHeader) {
      final headers = [
        LabelStore.get('PRODUCTION_TABLE_HEADER_CLIENT', '업체'),
        LabelStore.get('PRODUCTION_TABLE_HEADER_PROCESS', '공정'),
        LabelStore.get('PRODUCTION_TABLE_HEADER_UNIT', '단위'),
        LabelStore.get('PRODUCTION_TABLE_HEADER_VALUE', '실적'),
      ];
      return _cell(headers[column], isHeader: true);
    }

    final row = rows[vicinity.row - 1];
    return switch (column) {
      0 => _cell(row.clientName),
      1 => _cell(row.processName),
      2 => _cell(row.unitName),
      _ => _cell(formatNumber(row.result)),
    };
  }

  Widget _cell(String text, {bool isHeader = false}) {
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
        ),
      ),
    );
  }
}
