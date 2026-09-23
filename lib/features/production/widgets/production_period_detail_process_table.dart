import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:fprs_frontend/core/utils/label_store.dart';
import 'package:fprs_frontend/core/utils/number_format.dart';
import 'package:fprs_frontend/features/production/utils/production_period_detail_grouping.dart';

class ProductionPeriodDetailProcessTable extends StatelessWidget {
  final List<PeriodDetailProcessGroup> groups;
  final List<String> dates;
  final bool showWip;
  final bool Function(DateTime day)? isHoliday;

  const ProductionPeriodDetailProcessTable({
    super.key,
    required this.groups,
    required this.dates,
    required this.showWip,
    this.isHoliday,
  });

  static const _colProcessWidth = 56.0;
  static const _colItemWidth = 36.0;
  static const _dateColWidth = 52.0;
  static const _colSumWidth = 56.0;
  static const _colAverageWidth = 48.0;
  static const _rowHeight = 36.0;
  static const _headerRowHeight = 44.0;
  static const _leftColCount = 2;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);
  static const _weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
  static const _saturdayColor = Color(0xFF1565C0);
  static const _sundayHolidayColor = Color(0xFFD32F2F);

  List<PeriodDetailItemRow> get _rows =>
      groups.expand((g) => g.items).toList();

  int get _columnCount => _leftColCount + dates.length;
  int get _rowCount => 1 + _rows.length;

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
          _buildFixedRight(),
        ],
      ),
    );
  }

  TableSpan _buildColumnSpan(int column) {
    final width = switch (column) {
      0 => _colProcessWidth,
      1 => _colItemWidth,
      _ => _dateColWidth,
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
      extent: FixedTableSpanExtent(row == 0 ? _headerRowHeight : _rowHeight),
      backgroundDecoration:
          row == 0 ? const TableSpanDecoration(color: _headerColor) : null,
      foregroundDecoration: const TableSpanDecoration(
        border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
      ),
    );
  }

  (int, int)? _cellMerge(TableVicinity vicinity) {
    if (vicinity.row == 0 || vicinity.column != 0) return null;
    final groupIndex = (vicinity.row - 1) ~/ 2;
    return (groupIndex * 2 + 1, 2);
  }

  Widget _buildCell(TableVicinity vicinity) {
    if (vicinity.row == 0) return _headerCell(vicinity.column);

    final rowIndex = vicinity.row - 1;
    final group = groups[rowIndex ~/ 2];
    final item = _rows[rowIndex];

    if (vicinity.column == 0) return _cell(group.processName, wrap: true);
    if (vicinity.column == 1) return _cell(item.itemLabel);

    final value = item.values[vicinity.column - _leftColCount];
    return _cell(_fmtValue(value, isAmount: item.itemLabel == '금액'));
  }

  Widget _headerCell(int column) {
    if (column == 0) {
      return _cell(LabelStore.get('PRODUCTION_TABLE_HEADER_PROCESS', '공정'),
          isHeader: true);
    }
    if (column == 1) {
      return _cell(LabelStore.get('PRODUCTION_TABLE_HEADER_ITEM', '항목'),
          isHeader: true);
    }
    return _dateHeaderCell(dates[column - _leftColCount]);
  }

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
      decoration: const BoxDecoration(
        border: Border(left: BorderSide(color: _borderColor)),
      ),
      child: Row(
        children: [
          if (!showWip)
            _fixedColumn(
              width: _colSumWidth,
              headerLabel: LabelStore.get('PRODUCTION_TABLE_HEADER_SUM', '합계'),
              valueOf: (item) => _fmtValue(item.total, isAmount: item.itemLabel == '금액'),
            ),
          _fixedColumn(
            width: _colAverageWidth,
            headerLabel: LabelStore.get('PRODUCTION_TABLE_HEADER_AVERAGE', '평균'),
            valueOf: (item) => _fmtAverage(item.average, isAmount: item.itemLabel == '금액'),
            hasRightBorder: false,
          ),
        ],
      ),
    );
  }

  Widget _fixedColumn({
    required double width,
    required String headerLabel,
    required String Function(PeriodDetailItemRow item) valueOf,
    bool hasRightBorder = true,
  }) {
    return Container(
      width: width,
      decoration: hasRightBorder
          ? const BoxDecoration(
              border: Border(right: BorderSide(color: _borderColor)),
            )
          : null,
      child: Column(
        children: [
          _fixedCell(headerLabel, isHeader: true, height: _headerRowHeight),
          ..._rows.map((item) => _fixedCell(valueOf(item))),
        ],
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

  Widget _cell(String text, {bool isHeader = false, bool wrap = false}) {
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

  static final _averageFormat = NumberFormat('#,##0.0');

  String _fmtAverage(double? v, {required bool isAmount}) {
    if (v == null) return '-';
    return _averageFormat.format(isAmount ? v / 10000 : v);
  }
}
