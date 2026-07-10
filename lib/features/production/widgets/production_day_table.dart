import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:dpr_frontend/core/utils/label_store.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/features/production/utils/production_grouping.dart';

class ProductionDayTable extends StatelessWidget {
  final String rowLabelHeader;
  final List<ProductionDayRow> rows;
  final bool selectionMode;
  final Set<int> selectedRowGroupIds;
  final void Function(int rowGroupId)? onRowGroupLongPress;
  final void Function(int rowGroupId)? onRowGroupTap;

  const ProductionDayTable({
    super.key,
    required this.rowLabelHeader,
    required this.rows,
    this.selectionMode = false,
    this.selectedRowGroupIds = const <int>{},
    this.onRowGroupLongPress,
    this.onRowGroupTap,
  });

  static const _colLabel = 48.0;
  static const _colShift = 44.0;
  static const _colUnit = 52.0;
  static const _minDataColWidth = 60.0;
  static const _rowHeight = 36.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  int get _columnCount => 6;
  int get _rowCount => 1 + rows.length;

  bool _rowGroupHasData(int rowGroupId) {
    return rows.any((r) => r.rowGroupId == rowGroupId && r.productionId != null);
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        const pinnedWidth = _colLabel + _colShift + _colUnit;
        final dataColWidth =
            ((constraints.maxWidth - pinnedWidth) / 3).clamp(
          _minDataColWidth,
          double.infinity,
        );

        return SizedBox(
          height: _rowCount * _rowHeight,
          child: TableView.builder(
            columnCount: _columnCount,
            rowCount: _rowCount,
            pinnedColumnCount: 3,
            verticalDetails: const ScrollableDetails.vertical(
              physics: NeverScrollableScrollPhysics(),
            ),
            horizontalDetails: const ScrollableDetails.horizontal(
              physics: ClampingScrollPhysics(), // 가로 overscroll 방지
            ),
            columnBuilder: (column) => _buildColumnSpan(column, dataColWidth),
            rowBuilder: _buildRowSpan,
            cellBuilder: (context, vicinity) {
              final merge = _cellMerge(vicinity);
              Widget child = _buildCell(vicinity);

              if (vicinity.row > 0) {
                final dataRow = rows[vicinity.row - 1];
                if (_rowGroupHasData(dataRow.rowGroupId)) {
                  child = GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onLongPress: selectionMode
                        ? () => onRowGroupTap?.call(dataRow.rowGroupId)
                        : () => onRowGroupLongPress?.call(dataRow.rowGroupId),
                    onTap: selectionMode
                        ? () => onRowGroupTap?.call(dataRow.rowGroupId)
                        : null,
                    child: child,
                  );
                }
              }

              return TableViewCell(
                rowMergeStart: merge?.$1,
                rowMergeSpan: merge?.$2,
                child: child,
              );
            },
          ),
        );
      },
    );
  }

  TableSpan _buildColumnSpan(int column, double dataColWidth) {
    final width = switch (column) {
      0 => _colLabel,
      1 => _colShift,
      2 => _colUnit,
      _ => dataColWidth,
    };
    return TableSpan(
      extent: FixedTableSpanExtent(width),
      foregroundDecoration: const TableSpanDecoration(
        border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
      ),
    );
  }

  TableSpan _buildRowSpan(int row) {
    final isSelected = row > 0 &&
        selectedRowGroupIds.contains(rows[row - 1].rowGroupId);

    return TableSpan(
      extent: const FixedTableSpanExtent(_rowHeight),
      backgroundDecoration: row == 0
          ? const TableSpanDecoration(color: _headerColor)
          : isSelected
              ? const TableSpanDecoration(color: Color(0xFFE3F2FD))
              : null,
      foregroundDecoration: const TableSpanDecoration(
        border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
      ),
    );
  }

  // 업체/구분 열의 행 병합 정보
  (int, int)? _cellMerge(TableVicinity vicinity) {
    if (vicinity.row == 0) return null;
    final dataIndex = vicinity.row - 1;
    final row = rows[dataIndex];

    if (vicinity.column == 0) {
      // 업체/공정 열: 같은 rowGroupId를 가진 연속 행들을 병합
      final start = rows.indexWhere((r) => r.rowGroupId == row.rowGroupId);
      final span = rows.where((r) => r.rowGroupId == row.rowGroupId).length;
      return (start + 1, span);
    }

    if (vicinity.column == 1) {
      // 구분(주/야) 열: 같은 (rowGroupId, shift) 조합을 병합
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
      final headers = [
        rowLabelHeader,
        LabelStore.get('PRODUCTION_TABLE_HEADER_TYPE', '구분'),
        LabelStore.get('PRODUCTION_TABLE_HEADER_UNIT', '단위'),
        LabelStore.get('PRODUCTION_TABLE_HEADER_VALUE', '실적'),
        LabelStore.get('PRODUCTION_TABLE_HEADER_WIP', '재공'),
        LabelStore.get('PRODUCTION_TABLE_MONTH_CUMULATIVE_SUM', '당월 누적 실적 합계'),
      ];
      return _styledCell(headers[column], isHeader: true);
    }

    final row = rows[vicinity.row - 1];
    final isAmountRow = row.unitName == '금액';
    if (column == 0) return _styledCell(row.rowGroupName, wrap: true);
    if (column == 1) return _styledCell(row.shift);
    if (column == 2) return _styledCell(row.unitName);
    if (column == 3) {
      return _styledCell(isAmountRow ? formatManwon(row.value) : _fmt(row.value));
    }
    if (column == 4) {
      return _styledCell(isAmountRow ? formatManwon(row.wip) : _fmt(row.wip));
    }
    return _styledCell(
      isAmountRow ? formatManwon(row.monthlyCumulativeAmount) : _fmt(row.monthlyCumulativeResult),
    );
  }

  Widget _styledCell(String text, {bool isHeader = false, bool wrap = false}) {
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
        ),
      ),
    );
  }

  String _fmt(double? v) =>
      v == null || v == 0 ? '-' : formatNumber(v);
}