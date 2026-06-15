import 'package:flutter/material.dart';

// 테이블 = 헤더 + 데이터
//
//   SimpleDataTable(
//     headers: ['구분', '전기(Kwh)', '용수(t)'],
//     rows: [
//       ['H/E', '300', '2'],
//       ['정면', '10', '2'],
//     ],
//   )
//
// 선택 모드(selectionMode)일 때:
//   - 맨 앞에 체크박스 컬럼이 추가된다
//   - rowIds[i]가 있는 행만 long-press/tap으로 선택 가능
//   - rowIds[i] == null인 행(데이터 없음)은 체크박스 없이 빈 셀로 표시
class SimpleDataTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;
  final List<int?>? rowIds;
  final bool selectionMode;
  final Set<int>? selectedIds;
  final void Function(int id)? onRowLongPress;
  final void Function(int id)? onRowTap;

  const SimpleDataTable({
    super.key,
    required this.headers,
    required this.rows,
    this.rowIds,
    this.selectionMode = false,
    this.selectedIds,
    this.onRowLongPress,
    this.onRowTap,
  });

  // Table[TableRow[widget, widget...], TableRow, TableRow ...]
  @override
  Widget build(BuildContext context) {
    final offset = selectionMode ? 1 : 0;

    return Table(
      border: TableBorder.all(color: const Color(0xFFE0E0E0), width: 1),
      columnWidths: {
        if (selectionMode) 0: const FixedColumnWidth(40),
        for (int i = 0; i < headers.length; i++)
          i + offset: const FlexColumnWidth(),
      },
      children: [
        TableRow(
          // 헤더
          decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
          children: [
            if (selectionMode) _cell(''),
            // 헤더 문자열을 셀에 넣기
            ...headers.map((h) => _cell(h, isHeader: true)),
          ],
        ),
        for (var i = 0; i < rows.length; i++) _buildDataRow(i),
      ],
    );
  }

  TableRow _buildDataRow(int index) {
    final id = rowIds?[index];
    final isSelected = id != null && (selectedIds?.contains(id) ?? false);

    var cells = rows[index].map((t) => _cell(t)).toList();

    // 데이터가 있는 행만 long-press/tap으로 선택 가능
    if (id != null) {
      cells = cells
          .map<Widget>((cell) => GestureDetector(
                behavior: HitTestBehavior.opaque,
                onLongPress: () => onRowLongPress?.call(id),
                onTap: selectionMode ? () => onRowTap?.call(id) : null,
                child: cell,
              ))
          .toList();
    }

    if (selectionMode) {
      cells.insert(
        0,
        id == null
            ? _cell('')
            : Checkbox(
                value: isSelected,
                onChanged: (_) => onRowTap?.call(id),
              ),
      );
    }

    return TableRow(
      decoration:
          isSelected ? const BoxDecoration(color: Color(0xFFE3F2FD)) : null,
      children: cells,
    );
  }

  // 셀 하나 그리기
  Widget _cell(String text, {bool isHeader = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 4),
      child: Text(
        text,
        textAlign: TextAlign.center,
        style: TextStyle(
          fontWeight: isHeader ? FontWeight.bold : FontWeight.normal,
        ),
      ),
    );
  }
}