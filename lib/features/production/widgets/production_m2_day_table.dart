import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:fprs_frontend/core/utils/label_store.dart';
import 'package:fprs_frontend/core/utils/number_format.dart';
import 'package:fprs_frontend/features/production/utils/production_overview_grouping.dart';
import 'package:fprs_frontend/features/production/widgets/table_header_button.dart';

// [업체별 실적 합계] 일별보기 표. M2 컬럼만 기본으로 보여주고, PNL/LOT 등 나머지
// 단위는 '업체' 헤더 버튼 → 상세 바텀시트에서 보여준다 ([공정별 실적 합계]와 동일한 원칙).
// entries는 (업체, 공정) 조합 전체를 담고 있고, M2 데이터가 없는 조합은 값 칸만 '-'로
// 표시한다 — M2 데이터가 있는 행만 추려서 보여주면 다른 단위로만 입력된 실적이 표에서
// 통째로 빠지는 문제가 있었음.
class ProductionM2DayTable extends StatelessWidget {
  final List<ClientSummaryDisplayEntry> entries;
  final String unitName;
  final bool showAmount;
  // '업체' 헤더 셀의 버튼을 탭했을 때 호출된다.
  final VoidCallback? onClientHeaderTap;

  const ProductionM2DayTable({
    super.key,
    required this.entries,
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
  int get _rowCount => 1 + entries.length;

  double? _m2Result(ClientSummaryDisplayEntry entry) {
    final match =
        entry.unitResults.where((u) => u.unitName.toUpperCase() == 'M2');
    return match.isEmpty ? null : match.first.result;
  }

  double? _m2Wip(ClientSummaryDisplayEntry entry) {
    final match =
        entry.unitResults.where((u) => u.unitName.toUpperCase() == 'M2');
    return match.isEmpty ? null : match.first.wip;
  }

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
    final groupIndex = entries[vicinity.row - 1].clientGroupIndex;
    final start = entries.indexWhere((e) => e.clientGroupIndex == groupIndex);
    final span = entries.where((e) => e.clientGroupIndex == groupIndex).length;
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
        if (showAmount) LabelStore.get('PRODUCTION_TABLE_HEADER_VALUE_AMOUNT', '실적금액'),
      ];
      return _cell(headers[column - 1], isHeader: true);
    }

    final entry = entries[vicinity.row - 1];
    return switch (column) {
      0 => _cell(entry.clientName),
      1 => _cell(entry.processName),
      2 => _cell(_fmt(_m2Result(entry))),
      3 => _cell(_fmt(_m2Wip(entry))),
      _ => _cell(entry.totalAmount == null ? '-' : formatManwon(entry.totalAmount)),
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
