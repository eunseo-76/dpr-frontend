import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:dpr_frontend/core/utils/label_store.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/features/production/utils/production_day_m2_grouping.dart';
import 'package:dpr_frontend/features/production/widgets/table_header_button.dart';

class ProductionM2DayTable extends StatelessWidget {
  final List<ProductionM2DayRow> rows;
  final String unitName;
  final bool showAmount;
  // '업체' 헤더 셀의 버튼을 탭했을 때 호출된다.
  final VoidCallback? onClientHeaderTap;

  const ProductionM2DayTable({
    super.key,
    required this.rows,
    required this.unitName,
    required this.showAmount,
    this.onClientHeaderTap,
  });

  static const _colClient = 72.0;
  static const _colProcess = 72.0;
  static const _minValueColWidth = 64.0;
  static const _rowHeight = 36.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  int get _valueColCount => showAmount ? 3 : 2;
  int get _columnCount => 2 + _valueColCount;
  int get _rowCount => 1 + rows.length;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const pinnedWidth = _colClient + _colProcess;
        final valueColWidth =
            ((constraints.maxWidth - pinnedWidth) / _valueColCount)
                .clamp(_minValueColWidth, double.infinity);

        return SizedBox(
          height: _rowCount * _rowHeight,
          child: TableView.builder(
            columnCount: _columnCount,
            rowCount: _rowCount,
            pinnedColumnCount: 2,
            verticalDetails: const ScrollableDetails.vertical(
              physics: NeverScrollableScrollPhysics(),
            ),
            horizontalDetails: const ScrollableDetails.horizontal(
              physics: ClampingScrollPhysics(),
            ),
            columnBuilder: (column) => _buildColumnSpan(column, valueColWidth),
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

  TableSpan _buildColumnSpan(int column, double valueColWidth) {
    final width = switch (column) {
      0 => _colClient,
      1 => _colProcess,
      _ => valueColWidth,
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

  // 업체(0번 열)만 연속된 같은 그룹끼리 병합 (ProductionOverviewTable과 동일)
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
      if (column == 0) return _clientHeaderCell();
      final valueLabel = LabelStore.get('PRODUCTION_TABLE_HEADER_VALUE', '실적');
      final wipLabel = LabelStore.get('PRODUCTION_TABLE_HEADER_WIP', '재공');
      final headers = [
        LabelStore.get('PRODUCTION_TABLE_HEADER_PROCESS', '공정'),
        '$valueLabel($unitName)',
        '$wipLabel($unitName)',
        if (showAmount) LabelStore.get('PRODUCTION_TABLE_HEADER_AMOUNT', '금액'),
      ];
      return _cell(headers[column - 1], isHeader: true);
    }

    final row = rows[vicinity.row - 1];
    return switch (column) {
      0 => _cell(row.clientName),
      1 => _cell(row.processName),
      2 => _cell(_fmt(row.result)),
      3 => _cell(_fmt(row.wip)),
      _ => _cell(row.amount == null ? '-' : formatManwon(row.amount)),
    };
  }

  static String _fmt(double? value) =>
      value == null || value == 0 ? '-' : formatNumber(value);

  Widget _clientHeaderCell() {
    final label = LabelStore.get('PRODUCTION_TABLE_HEADER_CLIENT', '업체');
    if (onClientHeaderTap == null) return _cell(label, isHeader: true);
    return TableHeaderButton(label: label, onTap: onClientHeaderTap!);
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
