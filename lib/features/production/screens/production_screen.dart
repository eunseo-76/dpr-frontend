import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/services/production_service.dart';
import 'package:dpr_frontend/features/production/widgets/date_navigation.dart';
import 'package:dpr_frontend/features/production/widgets/period_selector.dart';
import 'package:dpr_frontend/features/production/widgets/production_table.dart';
import 'package:dpr_frontend/features/production/widgets/view_toggle.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';
import 'package:dpr_frontend/features/unit/services/unit_service.dart';
import 'package:flutter/material.dart';
import 'package:logger/logger.dart';

class ProductionScreen extends StatefulWidget {

  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  List<Unit> _units = [];
  List<Production> _productions = [];
  bool _isLoading = true;
  String? _error;
  bool _isProcessView = true;
  String _selectedPeriod = '일';
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);

  final _unitService = UnitService();
  final _productionService = ProductionService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  static const _periodTypeMap = {
    '일': 'DAY',
    '주': 'WEEK',
    '월': 'MONTH',
    '년': 'YEAR',
  };

  String _dateStr(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  void _navigateDate(int direction) {
    final d = DateTime.parse(_selectedDate);
    final DateTime next;
    switch (_selectedPeriod) {
      case '일':
        next = d.add(Duration(days: direction));
      case '주':
        next = d.add(Duration(days: direction * 7));
      case '월':
        next = DateTime(d.year, d.month + direction, 1);
      case '년':
        next = DateTime(d.year + direction, 1, 1);
      default:
        return;
    }
    setState(() => _selectedDate = _dateStr(next));
    _loadData();
  }

  Future<void> _onCalendarTap() async {
    final d = DateTime.parse(_selectedDate);
    final picked = await showDatePicker(
      context: context,
      initialDate: d,
      firstDate: DateTime(2020),
      lastDate: DateTime(2030),
    );
    if (picked != null) {
      setState(() => _selectedDate = _dateStr(picked));
      _loadData();
    }
  }

  String _displayLabel() {
    final d = DateTime.parse(_selectedDate);
    switch (_selectedPeriod) {
      case '일':
        return '${d.year}년 ${d.month}월 ${d.day}일';
      case '주':
        final monday = d.subtract(Duration(days: d.weekday - 1));
        final weekNum = (monday.day - 1) ~/7 + 1;
        return '${monday.year}년 ${monday.month}월 $weekNum주차';
      case '월':
        return '${d.year}년 ${d.month}월';
      case '년':
        return '${d.year}년';
      default:
        return _selectedDate;
    }
  }

  Future<void> _loadData() async {
    try {
      final factoryId = await UserStorage.getFactoryId();

      final results = await Future.wait([
        _unitService.getUnitList(factoryId: factoryId),
        _productionService.getProductionList(
          date: _selectedDate,
          periodType: _periodTypeMap[_selectedPeriod]!,
        ),
      ]);

      setState(() {
        _units = results[0] as List<Unit>;
        _productions = results[1] as List<Production>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) return const Center(child: CircularProgressIndicator());
    if (_error != null) return Center(child: Text('오류: $_error'));

    return Scaffold(
      appBar: AppBar(title: const Text('생산실적')),
      body: Column(
        children: [
          PeriodSelector(
            selectedPeriod: _selectedPeriod,
            onPeriodChanged: (period) {
              setState(() => _selectedPeriod = period);
              _loadData();
            },
          ),
          DateNavigation(
            date: _displayLabel(),
            onPrevious: () => _navigateDate(-1),
            onNext: () => _navigateDate(1),
            onCalendarTap: _onCalendarTap,
          ),
          ViewToggle(
            isProcessView: _isProcessView,
            onChanged: (value) => setState(() => _isProcessView = value),
          ),
          // production_table에 넘겨주기
          Expanded(
            child: ProductionTable(
              units: _units,
              productions: _productions,
              isProcessView: _isProcessView,
              selectedPeriod: _selectedPeriod,
              selectedDate: _selectedDate,
            ),
          ),
        ],
      ),
    );
  }
}
