import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/core/widgets/date_navigator.dart';
import 'package:dpr_frontend/core/widgets/segmented_toggle.dart';
import 'package:dpr_frontend/features/client/models/factory_client.dart';
import 'package:dpr_frontend/features/client/services/client_service.dart';
import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/services/production_service.dart';
import 'package:dpr_frontend/features/production/utils/production_grouping.dart';
import 'package:dpr_frontend/features/production/widgets/production_day_table.dart';
import 'package:dpr_frontend/features/production/utils/production_scaffold.dart';
import 'package:dpr_frontend/features/production/widgets/production_card.dart';
import 'package:dpr_frontend/features/production/widgets/production_table.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';
import 'package:dpr_frontend/features/unit/services/unit_service.dart';
import 'package:dpr_frontend/features/utility/models/factory_process.dart';
import 'package:dpr_frontend/features/utility/services/utility_service.dart';
import 'package:flutter/material.dart';

class ProductionScreen extends StatefulWidget {
  const ProductionScreen({super.key});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  List<Unit> _units = [];
  List<FactoryClient> _factoryClients = [];
  List<FactoryProcess> _factoryProcesses = [];
  List<Production> _productions = [];
  bool _isLoading = true;
  String? _error;
  String _groupBy = '공정별';
  String _selectedPeriod = '일';
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);

  final _unitService = UnitService();
  final _clientService = ClientService();
  final _utilityService = UtilityService();
  final _productionService = ProductionService();

  static const _periodTypeMap = {
    '일': 'DAY',
    '주': 'WEEK',
    '월': 'MONTH',
    '년': 'YEAR',
  };

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

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
    _loadProductions();
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
      _loadProductions();
    }
  }

  String _displayLabel() {
    final d = DateTime.parse(_selectedDate);
    const weekdayNames = ['월', '화', '수', '목', '금', '토', '일'];
    switch (_selectedPeriod) {
      case '일':
        return '${d.year}년 ${d.month}월 ${d.day}일 (${weekdayNames[d.weekday - 1]})';
      case '주':
        final monday = d.subtract(Duration(days: d.weekday - 1));
        final sunday = monday.add(const Duration(days: 6));
        return '${monday.month.toString().padLeft(2, '0')}월 ${monday.day.toString().padLeft(2, '0')}일 - ${sunday.month.toString().padLeft(2, '0')}월 ${sunday.day.toString().padLeft(2, '0')}일';
      case '월':
        return '${d.year}년 ${d.month}월';
      case '년':
        return '${d.year}년';
      default:
        return _selectedDate;
    }
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final factoryId = await UserStorage.getFactoryId();
      final results = await Future.wait([
        _unitService.getUnitList(factoryId: factoryId),
        _clientService.getFactoryClients(),
        _utilityService.getFactoryProcesses(),
        _productionService.getProductionList(
          date: _selectedDate,
          periodType: _periodTypeMap[_selectedPeriod]!,
        ),
      ]);
      setState(() {
        _units = results[0] as List<Unit>;
        _factoryClients = results[1] as List<FactoryClient>;
        _factoryProcesses = results[2] as List<FactoryProcess>;
        _productions = results[3] as List<Production>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadProductions() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final productions = await _productionService.getProductionList(
        date: _selectedDate,
        periodType: _periodTypeMap[_selectedPeriod]!,
      );
      setState(() => _productions = productions);
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

    Widget content;
    if (_selectedPeriod == '일') {
      content = _buildDayView();
    } else {
      content = ProductionTable(
        units: _units,
        productions: _productions,
        isProcessView: _groupBy == '공정별',
        selectedPeriod: _selectedPeriod,
        selectedDate: _selectedDate,
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text('생산실적')),
      body: Column(
        children: [
          SegmentedToggle(
            options: const ['공정별', '업체별'],
            selected: _groupBy,
            onChanged: (value) => setState(() => _groupBy = value),
          ),
          SegmentedToggle(
            options: const ['일', '주', '월', '년'],
            selected: _selectedPeriod,
            onChanged: (period) {
              setState(() => _selectedPeriod = period);
              _loadProductions();
            },
          ),
          DateNavigator(
            label: _displayLabel(),
            onPrevious: () => _navigateDate(-1),
            onNext: () => _navigateDate(1),
            onCalendarTap: _onCalendarTap,
          ),
          Expanded(child: content),
        ],
      ),
    );
  }

  Widget _buildDayView() {
    final scaffold = buildProductionScaffold(
      factoryProcesses: _factoryProcesses,
      factoryClients: _factoryClients,
      units: _units,
      groupBy: _groupBy,
    );
    final dayGroups = groupProductionsForDay(_productions, scaffold, _groupBy);
    final rowLabelHeader = _groupBy == '공정별' ? '업체' : '공정';

    return ListView(
      padding: const EdgeInsets.all(8),
      children: dayGroups.map((group) {
        final cardTitle = _groupBy == '공정별'
            ? '${group.groupName} 공정'
            : group.groupName;

        return ProductionCard(
          title: cardTitle,
          units: _units,
          footer: ProductionCardFooter(
            dailyByUnit: group.dailySumByUnit,
            cumulativeByUnit: group.cumulativeSumByUnit,
          ),
          table: ProductionDayTable(
            rowLabelHeader: rowLabelHeader,
            rows: group.rows,
          ),
        );
      }).toList(),
    );
  }
}