import 'dart:math';

import 'package:flutter/material.dart';
import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';

class ProductionTable extends StatelessWidget {
  final List<Unit> units;
  final List<Production> productions;
  final bool isProcessView;
  final String selectedPeriod;
  final String selectedDate;

  static const double _colProcess = 60;
  static const double _colClient = 90;
  static const double _colShift = 45;
  static const double _colUnit = 55;
  static const double _headerRowHeight = 28.0;
  static const double _dataRowHeight = 28.0;

  const ProductionTable({
    super.key,
    required this.units,
    required this.productions,
    required this.isProcessView,
    required this.selectedPeriod,
    required this.selectedDate,
  });

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: SingleChildScrollView(
        scrollDirection: Axis.vertical,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(),
            _buildDataRows(),
            _buildTotalSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader() {
    const double singleHeight = _headerRowHeight * 2;

    // 일 보기: 2단 헤더 — 공정/업체/주야(rowspan) + 단위 그룹
    if (selectedPeriod == '일') {
      return Row(
        children: [
          _headerCell('공정', _colProcess, height: singleHeight),
          _headerCell('업체', _colClient, height: singleHeight),
          _headerCell('주/야', _colShift, height: singleHeight),
          Column(
            children: [
              _headerCell('단위', units.length * _colUnit, height: _headerRowHeight, isGroup: true),
              Row(children: units.map((u) => _headerCell(u.name, _colUnit, height: _headerRowHeight)).toList()),
            ],
          ),
        ],
      );
    }
    // 주 보기: 요일 × 단위 2단 헤더
    if (selectedPeriod == '주') {
      return Row(
        children: [
          _headerCell('공정', _colProcess, height: singleHeight),
          _headerCell('업체', _colClient, height: singleHeight),
          _headerCell('주/야', _colShift, height: singleHeight),
          ..._weekDates().map((date) => Column(
            children: [
              _headerCell(_dayLabel(date), units.length * _colUnit, height: _headerRowHeight, isGroup: true),
              Row(children: units.map((u) => _headerCell(u.name, _colUnit, height: _headerRowHeight)).toList()),
            ],
          )),
        ],
      );
    }
    // 월 보기: 주차 × 단위 2단 헤더
    if (selectedPeriod == '월') {
      final weekRanges = _monthWeekRanges();
      return Row(
        children: [
          _headerCell('공정', _colProcess, height: singleHeight),
          _headerCell('업체', _colClient, height: singleHeight),
          _headerCell('주/야', _colShift, height: singleHeight),
          ...weekRanges.asMap().entries.map((e) => Column(
            children: [
              _headerCell('${e.key + 1}주', units.length * _colUnit, height: _headerRowHeight, isGroup: true),
              Row(children: units.map((u) => _headerCell(u.name, _colUnit, height: _headerRowHeight)).toList()),
            ],
          )),
        ],
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildDataRows() {
    // processId → clientId → unitId → List<Production> (날짜별 여러 개)
    final Map<int, Map<int, Map<int, List<Production>>>> grouped = {};
    for (final p in productions) {
      grouped.putIfAbsent(p.processId, () => {});
      grouped[p.processId]!.putIfAbsent(p.clientId, () => {});
      grouped[p.processId]![p.clientId]!.putIfAbsent(p.unitId, () => []);
      grouped[p.processId]![p.clientId]![p.unitId]!.add(p);
    }

    return Column(
      children: grouped.entries.map((processEntry) {
        final clients = processEntry.value;
        final processName = productions
            .firstWhere((p) => p.processId == processEntry.key)
            .processName;
        final processHeight = clients.length * 2 * _dataRowHeight;

        return Column(
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _dataCell(processName, _colProcess, height: processHeight),
                Column(
                  children: clients.entries.map(_buildClientGroup).toList(),
                ),
              ],
            ),
            ..._buildSubtotalRows(processEntry.key),
          ],
        );
      }).toList(),
    );
  }

  List<Widget> _buildSubtotalRows(int processId) {
    const double labelWidth = _colProcess + _colClient + _colShift;
    const bgGreen = Color(0xFFE8F5E9);

    String fmt(double v) =>
        v == 0 ? '-' : (v == v.truncateToDouble() ? v.toInt().toString() : v.toString());

    // 일 보기: 단위 열만
    if (selectedPeriod == '일') {
      return [
        Row(children: [
          _subtotalCell('일일실적', labelWidth),
          ...units.map((u) => _dataCell(fmt(_calcGroupSum(processId, u.id)), _colUnit, height: _dataRowHeight, bgColor: bgGreen)),
        ]),
        Row(children: [
          _subtotalCell('누적실적', labelWidth),
          ...units.map((u) => _dataCell(fmt(_calcGroupSum(processId, u.id, cumulative: true)), _colUnit, height: _dataRowHeight, bgColor: bgGreen)),
        ]),
      ];
    }

    // 월 보기: 주차 × 단위
    if (selectedPeriod == '월') {
      final ranges = _monthWeekRanges();
      final weeklySums = {
        for (final u in units)
          u.id: ranges.map((r) => _calcWeekSum(processId, u.id, r)).toList()
      };
      final cumulativeWeek = {
        for (final u in units)
          u.id: _calcCumulative(weeklySums[u.id]!)
      };

      return [
        Row(children: [
          _subtotalCell('주간실적', labelWidth),
          ...ranges.asMap().entries.expand((e) => units.map((u) =>
              _dataCell(fmt(weeklySums[u.id]![e.key]), _colUnit, height: _dataRowHeight, bgColor: bgGreen))),
        ]),
        Row(children: [
          _subtotalCell('누적실적', labelWidth),
          ...ranges.asMap().entries.expand((e) => units.map((u) =>
              _dataCell(fmt(cumulativeWeek[u.id]![e.key]), _colUnit, height: _dataRowHeight, bgColor: bgGreen))),
        ]),
      ];
    }

    // 주 보기: 요일 × 단위
    final dates = _weekDates();

    // 단위별 요일별 일일 합계
    final dailySums = {
      for (final u in units)
        u.id: dates.map((d) => _calcDaySum(processId, u.id, _dateStr(d))).toList()
    };
    // 단위별 누적 (running sum, 0이면 이전 값 유지)
    final cumulative = {
      for (final u in units)
        u.id: _calcCumulative(dailySums[u.id]!)
    };

    return [
      Row(children: [
        _subtotalCell('일일실적', labelWidth),
        ...dates.asMap().entries.expand((e) => units.map((u) =>
            _dataCell(fmt(dailySums[u.id]![e.key]), _colUnit, height: _dataRowHeight, bgColor: bgGreen))),
      ]),
      Row(children: [
        _subtotalCell('누적실적', labelWidth),
        ...dates.asMap().entries.expand((e) => units.map((u) =>
            _dataCell(fmt(cumulative[u.id]![e.key]), _colUnit, height: _dataRowHeight, bgColor: bgGreen))),
      ]),
    ];
  }

  // 특정 날짜의 공정+단위 소계
  double _calcDaySum(int processId, int unitId, String date) {
    return productions
        .where((p) => p.processId == processId && p.unitId == unitId && p.date == date)
        .fold(0.0, (sum, p) => sum + (p.result ?? 0));
  }

  double _calcWeekSum(int processId, int unitId, List<DateTime> range) {
    double sum = 0;
    for (var d = range[0]; !d.isAfter(range[1]); d = d.add(const Duration(days: 1))) {
      sum += _calcDaySum(processId, unitId, _dateStr(d));
    }
    return sum;
  }

  // 일일 합계 목록 → running sum (값이 0이면 이전 값 유지)
  List<double> _calcCumulative(List<double> dailySums) {
    double running = 0.0;
    return dailySums.map((v) {
      if (v != 0) running += v;
      return running;
    }).toList();
  }

  Widget _subtotalCell(String text, double width) {
    return Container(
      width: width,
      height: _dataRowHeight,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFE8F5E9),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _buildClientGroup(MapEntry<int, Map<int, List<Production>>> entry) {
    final clientName = productions
        .firstWhere((p) => p.clientId == entry.key)
        .clientName;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _dataCell(clientName, _colClient, height: 2 * _dataRowHeight),
        Column(
          children: [
            _buildShiftRow('주간', entry.value, isDayShift: true),
            _buildShiftRow('야간', entry.value, isDayShift: false),
          ],
        ),
      ],
    );
  }

  // TODO(human): selectedDate가 속한 월의 주 범위 목록을 반환하세요.
  // 각 주 범위는 [weekStart, weekEnd] 형태의 List<DateTime>입니다.
  //
  // 힌트:
  //   final d = DateTime.parse(selectedDate);
  //   final firstDay = DateTime(d.year, d.month, 1);         // 이번달 1일
  //   final lastDay  = DateTime(d.year, d.month + 1, 0);     // 이번달 마지막날
  //   final firstMonday = firstDay.subtract(Duration(days: firstDay.weekday - 1)); // 첫주 월요일
  //
  //   var weekStart = firstMonday;
  //   while (!weekStart.isAfter(lastDay)) { ... weekStart = weekStart.add(Duration(days: 7)); }
  //   각 주의 start = max(weekStart, firstDay), end = min(weekStart+6, lastDay)
  List<List<DateTime>> _monthWeekRanges() {
    final d = DateTime.parse(selectedDate);
    final firstDay = DateTime(d.year, d.month, 1);  // 이번달 1일
    final lastDay = DateTime(d.year, d.month + 1, 0); // 이번달 마지막 날
    final firstMonday = firstDay.subtract(Duration(days: firstDay.weekday - 1));  // 첫주 월요일

    final result = <List<DateTime>>[];
    var weekStart = firstMonday;

    while (!weekStart.isAfter(lastDay)) {
      final start = weekStart.isBefore(firstDay) ? firstDay: weekStart;
      final weekEnd = weekStart.add(const Duration(days: 6));
      final end = weekEnd.isAfter(lastDay) ? lastDay : weekEnd;
      result.add([start, end]);
      weekStart = weekStart.add(Duration(days: 7)); // 다음 주로
    }
    return result;
  }

  Row _buildShiftRow(String shift, Map<int, List<Production>> unitMap,
      {required bool isDayShift}) {

    Production? find(int unitId, String dateStr) {
      final matched = (unitMap[unitId] ?? []).where((p) => p.date == dateStr);
      return matched.isEmpty ? null : matched.first;
    }

    String val(Production? p) =>
        (isDayShift ? p?.dayShift : p?.nightShift)?.toString() ?? '-';

    if (selectedPeriod == '일') {
      return Row(children: [
        _dataCell(shift, _colShift, height: _dataRowHeight),
        ...units.map((u) => _dataCell(val(find(u.id, selectedDate)), _colUnit, height: _dataRowHeight)),
      ]);
    }

    // 월 보기: 주차별 합산
    if (selectedPeriod == '월') {
      return Row(children: [
        _dataCell(shift, _colShift, height: _dataRowHeight),
        ..._monthWeekRanges().expand((range) {
          return units.map((u) {
            double total = 0;
            for (var d = range[0]; !d.isAfter(range[1]); d = d.add(const Duration(days: 1))) {
              for (final p in (unitMap[u.id] ?? []).where((p) => p.date == _dateStr(d))) {
                total += (isDayShift ? p.dayShift : p.nightShift) ?? 0;
              }
            }
            return _dataCell(
              total == 0 ? '-' : (total == total.truncateToDouble() ? total.toInt().toString() : total.toString()),
              _colUnit,
              height: _dataRowHeight,
            );
          });
        }),
      ]);
    }

    // 주 보기: 요일 × 단위
    return Row(children: [
      _dataCell(shift, _colShift, height: _dataRowHeight),
      ..._weekDates().expand((date) {
        final dateStr = _dateStr(date);
        return units.map((u) => _dataCell(val(find(u.id, dateStr)), _colUnit, height: _dataRowHeight));
      }),
    ]);
  }

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  List<DateTime> _weekDates() {
    final d = DateTime.parse(selectedDate);
    final monday = d.subtract(Duration(days: d.weekday - 1));

    return List.generate(7, (i) => monday.add(Duration(days: i)));  // 월~일 7개
  }

  // record.date → 현재 기간새의 열 인덱스
  int _columnIndex(String date) {
    final d = DateTime.parse(date);
    switch (selectedPeriod) {
      case '주': return d.weekday - 1; // 월=0, 일=6
      default:   return 0;
    }
  }

  // DateTime → 요일 라벨
  String _dayLabel(DateTime d) {
    const labels = ['월', '화', '수', '목', '금', '토', '일'];
    return labels[d.weekday - 1];
  }

  // cumulative = false -> 일일실적
  // cumulative = true -> 누적실적
  double _calcGroupSum(int processId, int unitId, {bool cumulative = false}) {

    return productions
        .where((p) => p.processId == processId && p.unitId == unitId)
        .fold(0.0, (sum, p) => sum + ((cumulative ? p.cumulativeResult : p.result) ?? 0));
  }

  Widget _dataCell(String text, double width, {required double height, Color? bgColor}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: bgColor,
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12),
        ),
      ),
    );
  }

  Widget _buildTotalSection() {
    if (productions.isEmpty) return const SizedBox.shrink();

    const double labelWidth = _colProcess + _colClient + _colShift;
    const double totalHeight = _dataRowHeight * 3;
    const bgPink = Color(0xFFFCE4EC);

    // 공정별이면 공정, 업체별이면 업체를 열 그룹으로
    final Map<int, String> groups = isProcessView
        ? {for (final p in productions) p.processId: p.processName}
        : {for (final p in productions) p.clientId: p.clientName};

    String fmt(double v) =>
        v == 0 ? '-' : (v == v.truncateToDouble() ? v.toInt().toString() : v.toString());

    double calcTotal(int groupId, int unitId) {
      return productions
          .where((p) => (isProcessView ? p.processId : p.clientId) == groupId && p.unitId == unitId)
          .fold(0.0, (sum, p) => sum + (p.cumulativeResult ?? 0));
    }

    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _totalLabelCell('총합계\n실적', labelWidth, height: totalHeight),
        Column(
          children: [
            // 1줄: 공정(또는 업체) 이름
            Row(children: groups.entries
                .map((e) => _totalHeaderCell(e.value, units.length * _colUnit))
                .toList()),
            // 2줄: 단위 이름 반복
            Row(children: groups.keys
                .expand((_) => units.map((u) => _totalHeaderCell(u.name, _colUnit)))
                .toList()),
            // 3줄: 값
            Row(children: groups.entries
                .expand((e) => units.map((u) =>
                    _dataCell(fmt(calcTotal(e.key, u.id)), _colUnit, height: _dataRowHeight, bgColor: bgPink)))
                .toList()),
          ],
        ),
      ],
    );
  }

  Widget _totalLabelCell(String text, double width, {required double height}) {
    return Container(
      width: width,
      height: height,
      padding: const EdgeInsets.symmetric(horizontal: 8),
      decoration: BoxDecoration(
        color: const Color(0xFFFCE4EC),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Align(
        alignment: Alignment.centerLeft,
        child: Text(text, style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600)),
      ),
    );
  }

  Widget _totalHeaderCell(String text, double width) {
    return Container(
      width: width,
      height: _dataRowHeight,
      decoration: BoxDecoration(
        color: const Color(0xFFF8BBD0),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Center(
        child: Text(text,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
      ),
    );
  }

  // 헤더 행
  Widget _headerCell(String text, double width,
      {bool isGroup = false, double? height}) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: isGroup ? const Color(0xFFF5F5F5) : const Color(0xFFEEEEEE),
        border: Border.all(color: const Color(0xFFE0E0E0), width: 0.5),
      ),
      child: Center(
        child: Text(
          text,
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}