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
class SimpleDataTable extends StatelessWidget {
  final List<String> headers;
  final List<List<String>> rows;

  const SimpleDataTable({
    super.key,
    required this.headers,
    required this.rows,
  });

  // Table[TableRow[widget, widget...], TableRow, TableRow ...]
  @override
  Widget build(BuildContext context) {
    return Table(
      border: TableBorder.all(color: const Color(0xFFE0E0E0), width: 0.5),
      columnWidths: {
        for (int i=0; i < headers.length; i++)
          i : const FlexColumnWidth(),
      },
      children: [
        TableRow(
          // 헤더
          decoration: const BoxDecoration(color: Color(0xFFF5F5F5)),
          children: [
            // 헤더 문자열을 셀에 넣기
            ...headers.map((h) => _cell(h, isHeader: true))
          ],
        ),
        ...rows.map((row) => TableRow(children: row.map((t) => _cell(t)).toList()))
      ],
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