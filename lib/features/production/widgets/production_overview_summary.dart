import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:dpr_frontend/core/utils/label_store.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/features/production/utils/production_overview_grouping.dart';
import 'package:dpr_frontend/features/production/widgets/table_header_button.dart';

// [공정별 실적 합계] — ProductionM2DayTable(production_m2_day_table.dart)과 동일한
// TableView 그리드로 그린다. 테두리색/헤더색/행높이/폰트 상수도 그쪽과 맞춰서 고정한다.
// M2만 기본으로 보여주고, PNL/LOT 등 나머지 단위는 '공정' 헤더 버튼 → 상세 바텀시트에서 보여준다.
class ProductionOverviewSummary extends StatelessWidget {
  final List<ProcessSummaryDisplayEntry> entries;
  final bool showAmount;
  // '공정' 헤더 셀의 버튼을 탭했을 때 호출된다. row 자체는 더 이상 탭 불가.
  final VoidCallback? onProcessHeaderTap;

  const ProductionOverviewSummary({
    super.key,
    required this.entries,
    required this.showAmount,
    this.onProcessHeaderTap,
  });

  static const _colProcess = 72.0;
  static const _minValueColWidth = 64.0;
  static const _rowHeight = 36.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  int get _columnCount => showAmount ? 3 : 2;
  int get _rowCount => 1 + entries.length;

  double? _m2Result(ProcessSummaryDisplayEntry entry) {
    final match =
        entry.unitResults.where((u) => u.unitName.toUpperCase() == 'M2');
    return match.isEmpty ? null : match.first.result;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final valueColCount = showAmount ? 2 : 1;
        final valueColWidth = ((constraints.maxWidth - _colProcess) /
                valueColCount)
            .clamp(_minValueColWidth, double.infinity);

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
            columnBuilder: (column) => _buildColumnSpan(column, valueColWidth),
            rowBuilder: _buildRowSpan,
            cellBuilder: (context, vicinity) =>
                TableViewCell(child: _buildCell(vicinity)),
          ),
        );
      },
    );
  }

  TableSpan _buildColumnSpan(int column, double valueColWidth) {
    final width = switch (column) {
      0 => _colProcess,
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

  Widget _buildCell(TableVicinity vicinity) {
    final column = vicinity.column;

    if (vicinity.row == 0) {
      if (column == 0) return _processHeaderCell();
      final valueLabel = LabelStore.get('PRODUCTION_TABLE_HEADER_VALUE', '실적');
      final headers = [
        '$valueLabel(m2)',
        if (showAmount) LabelStore.get('PRODUCTION_TABLE_HEADER_AMOUNT', '금액'),
      ];
      return _cell(headers[column - 1], isHeader: true);
    }

    final entry = entries[vicinity.row - 1];
    if (column == 0) return _cell(entry.processName);

    if (column == 1) {
      final value = _m2Result(entry);
      return _cell(value == null || value == 0 ? '-' : formatNumber(value));
    }

    return _cell(
      entry.totalAmount == null ? '-' : formatManwon(entry.totalAmount),
    );
  }

  Widget _processHeaderCell() {
    final label = LabelStore.get('PRODUCTION_TABLE_HEADER_PROCESS', '공정');
    if (onProcessHeaderTap == null) return _cell(label, isHeader: true);
    return TableHeaderButton(label: label, onTap: onProcessHeaderTap!);
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