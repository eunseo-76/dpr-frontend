import 'package:dpr_frontend/features/utility/models/utility.dart';
import 'package:dpr_frontend/features/utility/services/utility_service.dart';
import 'package:dpr_frontend/features/utility/utils/utility_grouping.dart';
import 'package:dpr_frontend/features/utility/widgets/date_navigator.dart';
import 'package:dpr_frontend/features/utility/widgets/segmented_toggle.dart';
import 'package:dpr_frontend/features/utility/widgets/utility_card.dart';
import 'package:flutter/material.dart';

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});

  @override
  State<UtilityScreen> createState() => _UtilityScreenState();
}

class _UtilityScreenState extends State<UtilityScreen> {
  List<Utility> _utilities = [];
  bool _isLoading = true;
  String? _error;
  String _groupBy = '공장별';
  String _selectedPeriod = '일';
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);

  final _utilityService = UtilityService();

  static const _periodTypeMap = {
    '일': 'DAY',
    '주': 'WEEK',
    '월': 'MONTH',
    '년': 'YEAR',
  };

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _utilityService.getUtilityList(
        date: _selectedDate,
        periodType: _periodTypeMap[_selectedPeriod]!,
      );

      setState(() {
        _utilities = results;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  DateTime get _selectedDateTime => DateTime.parse(_selectedDate);

  String get _displayLabel {
    final date = _selectedDateTime;

    switch (_selectedPeriod) {
      case '일':
        const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
        final weekday = weekdayNames[date.weekday - 1];
        return '${date.year}년 ${date.month.toString().padLeft(2, '0')}월 ${date.day.toString().padLeft(2, '0')}일 ($weekday)';
      case '주':
        final monday = date.subtract(Duration(days: date.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        final mondayLabel =
            '${monday.month.toString().padLeft(2, '0')}월 ${monday.day.toString().padLeft(2, '0')}일';
        final sundayLabel =
            '${sunday.month.toString().padLeft(2, '0')}월 ${sunday.day.toString().padLeft(2, '0')}일';
        return '$mondayLabel - $sundayLabel';
      case '월':
        return '${date.year}년 ${date.month}월';
      case '년':
        return '${date.year}년';
      default:
        return _selectedDate;
    }
  }

  void _navigateDate(int direction) {
    final date = _selectedDateTime;
    late final DateTime newDate;

    switch (_selectedPeriod) {
      case '일':
        newDate = date.add(Duration(days: direction));
        break;
      case '주':
        newDate = date.add(Duration(days: 7 * direction));
        break;
      case '월':
        newDate = DateTime(date.year, date.month + direction, date.day);
        break;
      case '년':
        newDate = DateTime(date.year + direction, date.month, date.day);
        break;
      default:
        newDate = date;
    }

    setState(() {
      _selectedDate = newDate.toIso8601String().substring(0, 10);
    });
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    Widget content;
    if (_isLoading) {
      content = const Center(child: CircularProgressIndicator());
    } else if (_error != null) {
      content = Center(child: Text('오류: $_error'));
    } else {
      final groups = groupUtilities(_utilities, _groupBy);
      content = ListView(
        padding: const EdgeInsets.all(8),
        children: groups.map((group) => UtilityCard(group: group)).toList(),
      );
    }

    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            SegmentedToggle(
              options: const ['공장별', '공정별'],
              selected: _groupBy,
              onChanged: (value) {
                setState(() => _groupBy = value);
              },
            ),
            SegmentedToggle(
              options: const ['일', '주', '월', '년'],
              selected: _selectedPeriod,
              onChanged: (value) {
                setState(() => _selectedPeriod = value);
                _loadData();
              },
            ),
            DateNavigator(
              label: _displayLabel,
              onPrevious: () => _navigateDate(-1),
              onNext: () => _navigateDate(1),
              onCalendarTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDateTime,
                  firstDate: DateTime(2020),
                  lastDate: DateTime(2100),
                );
                if (picked != null) {
                  setState(() {
                    _selectedDate = picked.toIso8601String().substring(0, 10);
                  });
                  _loadData();
                }
              },
            ),
            Expanded(child: content),
          ],
        ),
      ),
    );
  }
}
