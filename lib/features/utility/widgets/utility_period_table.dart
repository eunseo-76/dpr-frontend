import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/features/utility/utils/utility_period_grouping.dart';

// 주/월/년 보기 표
// 컬럼: 구분 | 공정(또는 공장) | 기간열1...N | 합계
// 행: 헤더 1행 + 전기 행들 + 용수 행들
// 구분+공정/공장 컬럼은 TableView의 pinnedColumnCount로 왼쪽 고정
// 합계 컬럼만 따로 TableView 밖에 별도 위젯으로 그려 오른쪽에 고정
// (trailingPinnedColumnCount는 주/월/년 전환 시 columnCount가 바뀌면서
//  two_dimensional_scrollables가 뭔가 잘 안 됨...)
// 가운데 기간 컬럼들만 가로 스크롤됨
// columnLabels: 헤더에 표시할 문자열 (주 뷰: '08' 같은 일자, 월 뷰: '5/4~5/10' 같은 주간 범위)
class UtilityPeriodTable extends StatelessWidget {
  final String rowLabelHeader; // 공장별 뷰 -> '공정', 공정별 뷰 -> '공장'
  final List<String> columnLabels;
  final List<UtilityPeriodRowData> electricityRows;
  final List<UtilityPeriodRowData> waterRows;

  static const _categoryColumnWidth = 48.0;
  static const _labelColumnWidth = 64.0;
  static const _periodColumnWidth = 56.0;
  static const _totalColumnWidth = 64.0;
  static const _rowHeight = 40.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  const UtilityPeriodTable({
    super.key,
    required this.rowLabelHeader,
    required this.columnLabels,
    required this.electricityRows,
    required this.waterRows,
  });

  int get _columnCount => 2 + columnLabels.length;
  int get _rowCount => 1 + electricityRows.length + waterRows.length;

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
              pinnedColumnCount: 2,
              verticalDetails: const ScrollableDetails.vertical(
                physics: NeverScrollableScrollPhysics(),
              ),
              columnBuilder: _buildColumnSpan,
              rowBuilder: _buildRowSpan,
              cellBuilder: (context, vicinity) =>
                  TableViewCell(child: _cell(vicinity)),
            ),
          ),
          _buildTotalColumn(),
        ],
      ),
    );
  }

  TableSpan _buildColumnSpan(int column) {
    final double width;
    if (column == 0) {
      width = _categoryColumnWidth;
    } else if (column == 1) {
      width = _labelColumnWidth;
    } else {
      width = _periodColumnWidth;
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

  // "구분"(전기/용수) + "공정/공장" + 날짜별 값 + 합계 중 하나를 그리는 셀
  Widget _cell(TableVicinity vicinity) {
    final row = vicinity.row;
    final column = vicinity.column;
    final isHeader = row == 0;
    final dataRowIndex = row - 1;

    String text;
    if (column == 0) {
      if (isHeader) {
        text = '구분';
      } else if (dataRowIndex == 0 && electricityRows.isNotEmpty) {
        text = '전기';
      } else if (dataRowIndex == electricityRows.length &&
          waterRows.isNotEmpty) {
        text = '용수';
      } else {
        text = '';
      }
    } else if (column == 1) {
      text = isHeader ? rowLabelHeader : _rowFor(dataRowIndex).label;
    } else {
      final dateIndex = column - 2;
      if (isHeader) {
        text = columnLabels[dateIndex];
      } else {
        final value = _rowFor(dataRowIndex).values[dateIndex];
        text = value == null ? '-' : formatNumber(value);
      }
    }

    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 4),
      child: Text(
        text,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }

  // "합계" 컬럼. TableView 밖에서 별도로 그려 오른쪽에 고정시킨다
  Widget _buildTotalColumn() {
    return Container(
      width: _totalColumnWidth,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _borderColor)),
      ),
      child: Column(
        children: List.generate(_rowCount, (row) {
          final isHeader = row == 0;
          final dataRowIndex = row - 1;
          final text =
              isHeader ? '합계' : formatNumber(_rowFor(dataRowIndex).total);

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
              style: TextStyle(
                fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
              ),
            ),
          );
        }),
      ),
    );
  }

  // row 0은 헤더이므로, dataRowIndex(row - 1)를 electricityRows/waterRows로 매핑
  UtilityPeriodRowData _rowFor(int dataRowIndex) {
    if (dataRowIndex < electricityRows.length) {
      return electricityRows[dataRowIndex];
    }
    return waterRows[dataRowIndex - electricityRows.length];
  }
}
