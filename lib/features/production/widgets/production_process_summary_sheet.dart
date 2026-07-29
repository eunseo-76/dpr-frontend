import 'package:flutter/material.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:fprs_frontend/core/utils/label_store.dart';
import 'package:fprs_frontend/core/utils/number_format.dart';
import 'package:fprs_frontend/features/production/utils/production_overview_grouping.dart';

// [공정별 실적 합계] '공정' 헤더 버튼을 탭하면 뜨는 상세 — 조회 중인 기간(일/기간)의
// 전체 공정을 단위별 실적 + 금액으로 한 번에 보여준다. 캘린더 피커와 같은 바텀시트
// 그릇을 쓰되, 배경은 어둡게 하지 않는다 (뒤에 깔린 표와 비교하며 볼 수 있도록).
Future<void> showProductionProcessSummarySheet(
  BuildContext context, {
  required String factoryName,
  required List<ProcessSummaryDisplayEntry> entries,
  required bool showAmount,
  // 일별보기에서만 true. 기간별보기는 재공 원본 데이터가 없어 항상 false.
  required bool showWip,
  required List<String> unitNames,
}) {
  return showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    barrierColor: Colors.transparent,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => FractionallySizedBox(
      heightFactor: 0.6,
      child: _ProductionProcessSummarySheet(
        factoryName: factoryName,
        entries: entries,
        showAmount: showAmount,
        showWip: showWip,
        unitNames: unitNames,
      ),
    ),
  );
}

class _ProductionProcessSummarySheet extends StatelessWidget {
  final String factoryName;
  final List<ProcessSummaryDisplayEntry> entries;
  final bool showAmount;
  final bool showWip;
  final List<String> unitNames;

  const _ProductionProcessSummarySheet({
    required this.factoryName,
    required this.entries,
    required this.showAmount,
    required this.showWip,
    required this.unitNames,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Text(
                  '$factoryName 전체 공정',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SizedBox(
            width: double.infinity,
            child: Text(
              LabelStore.get('PRODUCTION_OVERVIEW_SUMMARY_TITLE_PROCESS', '[공정별 실적 합계]'),
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(height: 8),
          Expanded(
            child: _SummaryTable(
              entries: entries,
              showAmount: showAmount,
              showWip: showWip,
              unitNames: unitNames,
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryTable extends StatelessWidget {
  final List<ProcessSummaryDisplayEntry> entries;
  final bool showAmount;
  final bool showWip;
  // 실적이 있는 단위가 아니라, 공장이 실제로 쓰는 단위 전체 목록.
  // entry.unitResults만 보면 값이 0인 단위는 통째로 빠져서 행마다 컬럼이
  // 들쭉날쭉해지는 문제가 있음 — 단위는 항상 고정된 컬럼으로 두고, 값 없는
  // 칸만 '-'로 채운다.
  final List<String> unitNames;

  const _SummaryTable({
    required this.entries,
    required this.showAmount,
    required this.showWip,
    required this.unitNames,
  });

  static const _colProcess = 72.0;
  static const _minValueColWidth = 64.0;
  static const _rowHeight = 36.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  // 단위 하나당 실적 열 1개, 재공을 보여줄 땐 그 옆에 재공 열이 하나 더 붙는다
  // (production_client_summary_sheet.dart와 동일한 실적/재공 나란히 배치).
  int get _metricsPerUnit => showWip ? 2 : 1;
  int get _columnCount =>
      1 + unitNames.length * _metricsPerUnit + (showAmount ? 1 : 0);
  int get _rowCount => 1 + entries.length;

  double? _resultFor(ProcessSummaryDisplayEntry entry, String unitName) {
    final match = entry.unitResults
        .where((u) => u.unitName.toUpperCase() == unitName.toUpperCase());
    return match.isEmpty ? null : match.first.result;
  }

  double? _wipFor(ProcessSummaryDisplayEntry entry, String unitName) {
    final match = entry.unitResults
        .where((u) => u.unitName.toUpperCase() == unitName.toUpperCase());
    return match.isEmpty ? null : match.first.wip;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final valueColCount =
            unitNames.length * _metricsPerUnit + (showAmount ? 1 : 0);
        final valueColWidth = valueColCount == 0
            ? _minValueColWidth
            : ((constraints.maxWidth - _colProcess) / valueColCount)
                .clamp(_minValueColWidth, double.infinity);

        return TableView.builder(
          columnCount: _columnCount,
          rowCount: _rowCount,
          pinnedColumnCount: 1,
          verticalDetails: const ScrollableDetails.vertical(
            physics: ClampingScrollPhysics(),
          ),
          horizontalDetails: const ScrollableDetails.horizontal(
            physics: ClampingScrollPhysics(),
          ),
          columnBuilder: (column) => TableSpan(
            extent: FixedTableSpanExtent(column == 0 ? _colProcess : valueColWidth),
            foregroundDecoration: const TableSpanDecoration(
              border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
            ),
          ),
          rowBuilder: (row) => TableSpan(
            extent: const FixedTableSpanExtent(_rowHeight),
            backgroundDecoration:
                row == 0 ? const TableSpanDecoration(color: _headerColor) : null,
            foregroundDecoration: const TableSpanDecoration(
              border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
            ),
          ),
          cellBuilder: (context, vicinity) =>
              TableViewCell(child: _buildCell(vicinity)),
        );
      },
    );
  }

  Widget _buildCell(TableVicinity vicinity) {
    final column = vicinity.column;
    final valueLabel = LabelStore.get('PRODUCTION_TABLE_HEADER_VALUE', '실적');
    final wipLabel = LabelStore.get('PRODUCTION_TABLE_HEADER_WIP', '재공');

    if (vicinity.row == 0) {
      final headers = [
        LabelStore.get('PRODUCTION_TABLE_HEADER_PROCESS', '공정'),
        for (final u in unitNames) ...[
          '$valueLabel($u)',
          if (showWip) '$wipLabel($u)',
        ],
        if (showAmount) LabelStore.get('PRODUCTION_TABLE_HEADER_VALUE_AMOUNT', '실적금액'),
      ];
      return _cell(headers[column], isHeader: true);
    }

    final entry = entries[vicinity.row - 1];
    if (column == 0) return _cell(entry.processName);

    final amountColumn = 1 + unitNames.length * _metricsPerUnit;
    if (showAmount && column == amountColumn) {
      return _cell(
        entry.totalAmount == null ? '-' : formatManwon(entry.totalAmount),
      );
    }

    final unitName = unitNames[(column - 1) ~/ _metricsPerUnit];
    final isWipColumn = showWip && (column - 1) % _metricsPerUnit == 1;
    final value =
        isWipColumn ? _wipFor(entry, unitName) : _resultFor(entry, unitName);
    return _cell(value == null || value == 0 ? '-' : formatNumber(value));
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
