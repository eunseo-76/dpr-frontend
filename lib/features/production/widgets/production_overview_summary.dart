import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:dpr_frontend/core/utils/label_store.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/features/production/utils/production_overview_grouping.dart';

// [공정별 실적 합계] — ProductionM2DayTable(production_m2_day_table.dart)과 동일한
// TableView 그리드로 그린다. 테두리색/헤더색/행높이/폰트 상수도 그쪽과 맞춰서 고정한다.
// M2만 기본으로 보여주고, PNL/LOT 등 나머지 단위는 셀 탭 → 상세 팝업(추후 구현)에서 보여준다.
// 맨 끝에 좁은 액션 열을 두고 펼쳐보기(화살표) 아이콘으로 "탭하면 상세가 있다"를 알려준다.
class ProductionOverviewSummary extends StatelessWidget {
  final List<ProcessSummaryDisplayEntry> entries;
  final bool showAmount;
  final void Function(ProcessSummaryDisplayEntry entry)? onRowTap;

  const ProductionOverviewSummary({
    super.key,
    required this.entries,
    required this.showAmount,
    this.onRowTap,
  });

  static const _colProcess = 72.0;
  static const _colAction = 28.0;
  static const _minValueColWidth = 64.0;
  static const _rowHeight = 36.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  int get _amountColumn => showAmount ? 2 : -1;
  int get _actionColumn => showAmount ? 3 : 2;
  int get _columnCount => _actionColumn + 1;
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
        final valueColWidth = ((constraints.maxWidth - _colProcess - _colAction) /
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
            cellBuilder: (context, vicinity) {
              Widget child = _buildCell(vicinity);
              if (vicinity.row > 0 && onRowTap != null) {
                final entry = entries[vicinity.row - 1];
                child = GestureDetector(
                  behavior: HitTestBehavior.opaque,
                  onTap: () => onRowTap!(entry),
                  child: child,
                );
              }
              return TableViewCell(child: child);
            },
          ),
        );
      },
    );
  }

  TableSpan _buildColumnSpan(int column, double valueColWidth) {
    final width = switch (column) {
      0 => _colProcess,
      _ when column == _actionColumn => _colAction,
      _ => valueColWidth,
    };
    return TableSpan(extent: FixedTableSpanExtent(width));
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
      final valueLabel = LabelStore.get('PRODUCTION_TABLE_HEADER_VALUE', '실적');
      final headers = [
        LabelStore.get('PRODUCTION_TABLE_HEADER_PROCESS', '공정'),
        '$valueLabel(m2)',
        if (showAmount) LabelStore.get('PRODUCTION_TABLE_HEADER_AMOUNT', '금액'),
        '', // 액션 열: 헤더 없음
      ];
      return _cell(headers[column], isHeader: true);
    }

    final entry = entries[vicinity.row - 1];
    if (column == 0) return _cell(entry.processName);

    if (column == 1) {
      final value = _m2Result(entry);
      return _cell(value == null || value == 0 ? '-' : formatNumber(value));
    }

    if (column == _amountColumn) {
      return _cell(
        entry.totalAmount == null ? '-' : formatManwon(entry.totalAmount),
      );
    }

    // 액션 열: 탭하면 상세 팝업이 뜬다는 표시
    return Center(
      child: Icon(Icons.open_in_full, size: 14, color: Colors.grey[500]),
    );
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