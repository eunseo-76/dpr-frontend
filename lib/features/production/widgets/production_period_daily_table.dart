import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:fprs_frontend/core/utils/label_store.dart';
import 'package:fprs_frontend/core/utils/number_format.dart';
import 'package:fprs_frontend/features/production/utils/production_period_daily_grouping.dart';

// 기간별(일별) 표. 실적 모드: 공정|구분·교대|항목 + 날짜별 컬럼 + 합계(sticky-right).
class ProductionPeriodDailyTable extends StatelessWidget {
  final List<PeriodDailyRow> rows;
  final List<String> dates;
  final bool showWip;
  final bool Function(DateTime day)? isHoliday;

  const ProductionPeriodDailyTable({
    super.key,
    required this.rows,
    required this.dates,
    required this.showWip,
    this.isHoliday,
  });

  static const _colProcessWidth = 48.0;
  static const _colShiftWidth = 26.0;
  static const _colAverageWidth = 40.0;
  static const _colItemWidth = 34.0;
  static const _dateColWidth = 56.0;
  static const _fixedColWidth = 56.0;
  static const _rowHeight = 36.0;
  static const _headerRowHeight = 44.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);
  static const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];

  int get _leftColCount => showWip ? 4 : 3;
  int get _columnCount => _leftColCount + dates.length;
  int get _rowCount => 1 + rows.length;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: _headerRowHeight + (_rowCount - 1) * _rowHeight,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: TableView.builder(
              columnCount: _columnCount,
              rowCount: _rowCount,
              pinnedColumnCount: _leftColCount,
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
          if (!showWip) _buildFixedRight(),
        ],
      ),
    );
  }

  TableSpan _buildColumnSpan(int column) {
    final double width;
    if (column == 0) {
      width = _colProcessWidth;
    } else if (column == 1) {
      width = _colShiftWidth;
    } else if (showWip && column == 2) {
      width = _colAverageWidth;
    } else if (column == _leftColCount - 1) {
      width = _colItemWidth;
    } else {
      width = _dateColWidth;
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
      extent: FixedTableSpanExtent(row == 0 ? _headerRowHeight : _rowHeight),
      backgroundDecoration:
          row == 0 ? const TableSpanDecoration(color: _headerColor) : null,
      foregroundDecoration: const TableSpanDecoration(
        border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
      ),
    );
  }

  // 공정 열은 같은 processId 전체(주+야, 실적+금액 행)를 하나로 병합, 구분/평균 열은
  // 같은 (processId, shift) 안의 실적행+금액행 2개만 병합. 항목/날짜 열은 병합 없음.
  (int, int)? _cellMerge(TableVicinity vicinity) {
    if (vicinity.row == 0) return null;
    final row = rows[vicinity.row - 1];

    if (vicinity.column == 0) {
      final start = rows.indexWhere((r) => r.processId == row.processId);
      final span = rows.where((r) => r.processId == row.processId).length;
      return (start + 1, span);
    }
    if (vicinity.column == 1 || (showWip && vicinity.column == 2)) {
      final start = rows.indexWhere(
          (r) => r.processId == row.processId && r.shift == row.shift);
      final span = rows
          .where((r) => r.processId == row.processId && r.shift == row.shift)
          .length;
      return (start + 1, span);
    }
    return null;
  }

  Widget _buildCell(TableVicinity vicinity) {
    final isHeader = vicinity.row == 0;
    final column = vicinity.column;

    if (isHeader) return _headerCell(column);

    final row = rows[vicinity.row - 1];
    if (column == 0) return _styledCell(row.processName, wrap: true);
    if (column == 1) return _styledCell(row.shift);
    if (showWip && column == 2) return _styledCell(_fmtAverage(row.average));
    if (column == _leftColCount - 1) return _styledCell(row.itemLabel);

    final value = row.values[column - _leftColCount];
    return _styledCell(_fmtValue(value, isAmount: row.itemLabel == '금액'));
  }

  Widget _headerCell(int column) {
    if (column == 0) {
      return _styledCell(
          LabelStore.get('PRODUCTION_TABLE_HEADER_PROCESS', '공정'),
          isHeader: true);
    }
    if (column == 1) {
      return _styledCell(LabelStore.get('PRODUCTION_TABLE_HEADER_TYPE', '구분'),
          isHeader: true);
    }
    if (showWip && column == 2) {
      return _styledCell(LabelStore.get('PRODUCTION_TABLE_HEADER_AVERAGE', '평균'),
          isHeader: true);
    }
    if (column == _leftColCount - 1) {
      return _styledCell(LabelStore.get('PRODUCTION_TABLE_HEADER_ITEM', '항목'),
          isHeader: true);
    }
    final date = dates[column - _leftColCount];
    return _dateHeaderCell(date);
  }

  static const _saturdayColor = Color(0xFF1565C0);
  static const _sundayHolidayColor = Color(0xFFD32F2F);

  // 공휴일이 토요일과 겹치면 파랑(토요일)이 아니라 빨강(공휴일)이 우선한다 —
  // 그래서 공휴일 여부를 요일 체크보다 먼저 확인한다.
  Color? _weekdayColor(DateTime d) {
    if (isHoliday?.call(d) ?? false) return _sundayHolidayColor;
    if (d.weekday == DateTime.sunday) return _sundayHolidayColor;
    if (d.weekday == DateTime.saturday) return _saturdayColor;
    return null;
  }

  Widget _dateHeaderCell(String isoDate) {
    final d = DateTime.parse(isoDate);
    final weekday = _weekdayNames[d.weekday - 1];
    final shortDate =
        '${d.month.toString().padLeft(2, '0')}/${d.day.toString().padLeft(2, '0')}';
    final color = _weekdayColor(d);
    return Container(
      alignment: Alignment.center,
      padding: const EdgeInsets.symmetric(horizontal: 2),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(weekday,
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: color)),
          Text(shortDate,
              style: TextStyle(fontSize: 9, color: color ?? Colors.grey[600])),
        ],
      ),
    );
  }

  Widget _buildFixedRight() {
    return Container(
      width: _fixedColWidth,
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _borderColor)),
      ),
      child: Column(
        children: List.generate(_rowCount, (i) {
          if (i == 0) {
            return _fixedCell(LabelStore.get('PRODUCTION_TABLE_HEADER_SUM', '합계'),
                isHeader: true, height: _headerRowHeight);
          }
          final row = rows[i - 1];
          return _fixedCell(_fmtValue(row.total, isAmount: row.itemLabel == '금액'));
        }),
      ),
    );
  }

  Widget _fixedCell(String text, {bool isHeader = false, double height = _rowHeight}) {
    return Container(
      height: height,
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

  String _fmtValue(double? v, {required bool isAmount}) {
    if (v == null || v == 0) return '-';
    return isAmount ? formatManwon(v) : formatNumber(v);
  }

  String _fmtAverage(double? v) => v == null ? '-' : v.toStringAsFixed(1);
}
