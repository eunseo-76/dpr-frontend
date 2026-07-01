import 'package:flutter/material.dart';
import 'package:table_calendar/table_calendar.dart';

Future<DateTime?> showCalendarPicker(BuildContext context, DateTime initial) {
  return showModalBottomSheet<DateTime>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.white,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
    ),
    builder: (_) => _CalendarSheet(initial: initial),
  );
}

class _CalendarSheet extends StatefulWidget {
  final DateTime initial;
  const _CalendarSheet({required this.initial});

  @override
  State<_CalendarSheet> createState() => _CalendarSheetState();
}

class _CalendarSheetState extends State<_CalendarSheet> {
  late DateTime _focused;
  late DateTime _selected;
  bool _showYearPicker = false;

  static const _rowHeight = 40.0;
  static const _dowHeight = 26.0;
  static const _headerHeight = 48.0;
  static const _yearPickerHeight = _headerHeight + 280.0;

  @override
  void initState() {
    super.initState();
    _focused = widget.initial;
    _selected = widget.initial;
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 36,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            _showYearPicker ? _buildYearPicker() : _buildCalendar(),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: TextButton(
                onPressed: () => Navigator.pop(context, _selected),
                style: TextButton.styleFrom(
                  backgroundColor: Colors.black87,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  '선택',
                  style: TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
    );
  }

  Widget _buildCalendar() {
    return TableCalendar(
        locale: 'ko_KR',
        firstDay: DateTime(2020),
        lastDay: DateTime(2030),
        focusedDay: _focused,
        selectedDayPredicate: (day) => isSameDay(day, _selected),
        calendarFormat: CalendarFormat.month,
        availableCalendarFormats: const {CalendarFormat.month: ''},
        rowHeight: _rowHeight,
        daysOfWeekHeight: _dowHeight,
        onDaySelected: (selected, focused) {
          setState(() {
            _selected = selected;
            _focused = focused;
          });
        },
        onPageChanged: (focused) => setState(() => _focused = focused),
        onHeaderTapped: (_) => setState(() => _showYearPicker = true),
        headerStyle: HeaderStyle(
          formatButtonVisible: false,
          titleCentered: true,
          headerPadding: const EdgeInsets.symmetric(vertical: 8),
          titleTextFormatter: (date, _) => '${date.year}년 ${date.month}월  ▾',
          titleTextStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w600,
            color: Colors.black87,
            decoration: TextDecoration.none,
          ),
          leftChevronIcon: const Icon(Icons.chevron_left_rounded, size: 22, color: Colors.black87),
          rightChevronIcon: const Icon(Icons.chevron_right_rounded, size: 22, color: Colors.black87),
        ),
        calendarStyle: CalendarStyle(
          outsideDaysVisible: true,
          selectedDecoration: const BoxDecoration(color: Colors.black87, shape: BoxShape.circle),
          todayDecoration: BoxDecoration(color: Colors.grey[200], shape: BoxShape.circle),
          selectedTextStyle: const TextStyle(color: Colors.white, fontSize: 14, decoration: TextDecoration.none),
          todayTextStyle: const TextStyle(color: Colors.black87, fontWeight: FontWeight.w600, fontSize: 14, decoration: TextDecoration.none),
          weekendTextStyle: const TextStyle(color: Colors.redAccent, fontSize: 14, decoration: TextDecoration.none),
          defaultTextStyle: const TextStyle(color: Colors.black87, fontSize: 14, decoration: TextDecoration.none),
          outsideTextStyle: TextStyle(color: Colors.grey[400], fontSize: 14, decoration: TextDecoration.none),
          disabledTextStyle: const TextStyle(color: Colors.transparent, fontSize: 14, decoration: TextDecoration.none),
        ),
        daysOfWeekStyle: const DaysOfWeekStyle(
          weekdayStyle: TextStyle(fontSize: 12, color: Colors.black54, decoration: TextDecoration.none),
          weekendStyle: TextStyle(fontSize: 12, color: Colors.redAccent, decoration: TextDecoration.none),
        ),
    );
  }

  Widget _buildYearPicker() {
    final years = List.generate(11, (i) => 2020 + i);
    return SizedBox(
      height: _yearPickerHeight,
      child: Column(
        children: [
          SizedBox(
            height: _headerHeight,
            child: GestureDetector(
              onTap: () => setState(() => _showYearPicker = false),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '${_focused.year}년',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(width: 4),
                  const Icon(Icons.expand_less_rounded, size: 18, color: Colors.black54),
                ],
              ),
            ),
          ),
          Expanded(
            child: GridView.count(
              crossAxisCount: 4,
              childAspectRatio: 1.8,
              mainAxisSpacing: 8,
              crossAxisSpacing: 8,
              children: years.map((year) {
                final isSelected = year == _focused.year;
                return GestureDetector(
                  onTap: () => setState(() {
                    _focused = DateTime(year, _focused.month);
                    _showYearPicker = false;
                  }),
                  child: Container(
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color: isSelected ? Colors.black87 : Colors.grey[100],
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      '$year',
                      style: TextStyle(
                        color: isSelected ? Colors.white : Colors.black87,
                        fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                        fontSize: 14,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ],
      ),
    );
  }
}