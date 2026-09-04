import 'package:fprs_frontend/core/constants/api_constants.dart';
import 'package:fprs_frontend/core/models/factory_summary.dart';
import 'package:fprs_frontend/core/models/master_data_entity.dart';
import 'package:fprs_frontend/core/services/master_data_service.dart';
import 'package:fprs_frontend/core/widgets/calendar_picker.dart';
import 'package:fprs_frontend/core/widgets/loading_indicator.dart';
import 'package:fprs_frontend/core/widgets/pill_selector.dart';
import 'package:fprs_frontend/core/widgets/segmented_toggle.dart';
import 'package:fprs_frontend/features/production/models/production.dart';
import 'package:fprs_frontend/features/production/models/production_overview.dart';
import 'package:fprs_frontend/features/production/services/production_service.dart';
import 'package:fprs_frontend/features/production_comparison/models/process_metric_row.dart';
import 'package:fprs_frontend/features/production_comparison/utils/comparison_date_preset.dart';
import 'package:fprs_frontend/features/production_comparison/utils/comparison_diff.dart';
import 'package:fprs_frontend/features/production_comparison/utils/process_metric_grouping.dart';
import 'package:fprs_frontend/features/production_comparison/widgets/comparison_date_row.dart';
import 'package:fprs_frontend/features/production_comparison/widgets/diverging_bar_row.dart';
import 'package:fprs_frontend/features/production_comparison/widgets/process_comparison_table.dart';
import 'package:fprs_frontend/features/production_comparison/widgets/simple_dropdown_button.dart';
import 'package:fprs_frontend/features/settings/models/factory_unit.dart';
import 'package:fprs_frontend/features/settings/services/factory_mapping_service.dart';
import 'package:fprs_frontend/features/utility/models/factory_process.dart';
import 'package:flutter/material.dart';

class ProductionComparisonScreen extends StatefulWidget {
  const ProductionComparisonScreen({super.key});

  @override
  State<ProductionComparisonScreen> createState() => _ProductionComparisonScreenState();
}

class _ProductionComparisonScreenState extends State<ProductionComparisonScreen> {
  static const _presetOrder = ['year', 'month', 'custom'];

  final _productionService = ProductionService();
  final _factoryMappingService = FactoryMappingService();

  List<FactorySummary> _factories = [];
  int? _selectedFactoryId;
  bool _isLoading = true;
  String? _error;

  List<FactoryUnit> _allFactoryUnits = [];
  String? _selectedUnit;
  List<FactoryProcess> _allFactoryProcesses = [];

  Map<int, String> get _processNameLookup =>
      {for (final p in _allFactoryProcesses) p.processId: p.processNickname ?? p.processName};

  List<int> get _processIdsForSelectedFactory => _allFactoryProcesses
      .where((p) => p.factoryId == _selectedFactoryId)
      .map((p) => p.processId)
      .toList();

  String _period = 'day';
  String _graphMetric = 'result';

  List<FactoryUnit> get _unitsForSelectedFactory =>
      _allFactoryUnits.where((u) => u.factoryId == _selectedFactoryId).toList();

  String get _selectedUnitLabel {
    final unit = _unitsForSelectedFactory.where((u) => u.unitName == _selectedUnit);
    if (unit.isEmpty) return _selectedUnit ?? '';
    return unit.first.unitNickname ?? unit.first.unitName;
  }

  String? _defaultUnit(List<FactoryUnit> units) {
    if (units.isEmpty) return null;
    final m2 = units.where((u) => u.unitName.toUpperCase() == 'M2');
    return m2.isNotEmpty ? m2.first.unitName : units.first.unitName;
  }

  String _preset = 'year';
  DateTime _dateA = DateTime.now();
  late DateTime _dateB = DateTime(_dateA.year - 1, _dateA.month, _dateA.day);

  bool _isDataLoading = false;
  String? _dataError;
  List<Production> _rawProductionsA = [];
  List<Production> _rawProductionsB = [];
  List<ProcessSummaryEntry> _summaryA = [];
  List<ProcessSummaryEntry> _summaryB = [];

  @override
  void initState() {
    super.initState();
    _loadFactories();
  }

  Future<void> _loadFactories() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final results = await Future.wait([
        MasterDataService(endpoint: ApiConstants.factory_, idKey: 'factoryId').getAll(),
        _factoryMappingService.getFactoryUnits(),
        _factoryMappingService.getFactoryProcesses(),
      ]);
      final entities = results[0] as List<MasterDataEntity>;
      final factories =
          entities.map((e) => FactorySummary(factoryId: e.id, factoryName: e.name)).toList();
      final allUnits = results[1] as List<FactoryUnit>;
      final allProcesses = results[2] as List<FactoryProcess>;

      setState(() {
        _factories = factories;
        _selectedFactoryId = factories.isEmpty ? null : factories.first.factoryId;
        _allFactoryUnits = allUnits;
        _allFactoryProcesses = allProcesses;
        _selectedUnit = _defaultUnit(_unitsForSelectedFactory);
      });
      if (factories.isNotEmpty) await _reloadComparisonData();
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  String _isoDate(DateTime d) =>
      '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';

  Future<void> _reloadComparisonData() async {
    final factoryId = _selectedFactoryId;
    if (factoryId == null) return;

    setState(() {
      _isDataLoading = true;
      _dataError = null;
    });
    try {
      final results = await Future.wait([
        _productionService.getProductionList(date: _isoDate(_dateA), periodType: 'DAY'),
        _productionService.getProductionList(date: _isoDate(_dateB), periodType: 'DAY'),
        _productionService.getProductionOverview(
          factoryId: factoryId,
          dateFrom: '${_dateA.year}-01-01',
          dateTo: _isoDate(_dateA),
        ),
        _productionService.getProductionOverview(
          factoryId: factoryId,
          dateFrom: '${_dateB.year}-01-01',
          dateTo: _isoDate(_dateB),
        ),
      ]);

      final productionsA =
          (results[0] as ({List<Production> productions, List<ProductionMonthlyCumulative> monthlyCumulative}))
              .productions;
      final productionsB =
          (results[1] as ({List<Production> productions, List<ProductionMonthlyCumulative> monthlyCumulative}))
              .productions;
      final overviewA = results[2] as ProductionOverview;
      final overviewB = results[3] as ProductionOverview;

      setState(() {
        _rawProductionsA = productionsA;
        _rawProductionsB = productionsB;
        _summaryA = overviewA.processSummary;
        _summaryB = overviewB.processSummary;
      });
    } catch (e) {
      setState(() => _dataError = e.toString());
    } finally {
      setState(() => _isDataLoading = false);
    }
  }

  String _dateLabel(DateTime d) =>
      '${(d.year % 100).toString().padLeft(2, '0')}.'
      '${d.month.toString().padLeft(2, '0')}.'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickDateA() async {
    final picked = await showCalendarPicker(context, _dateA);
    if (picked == null) return;
    setState(() {
      _dateA = picked;

      if (_preset != 'custom') {
        _dateB = computePresetDateB(dateA: _dateA, preset: _preset);
      }
    });
    await _reloadComparisonData();
  }

  Future<void> _pickDateB() async {
    final picked = await showCalendarPicker(context, _dateB);
    if (picked == null) return;
    setState(() {
      _dateB = picked;
      _preset = 'custom';
    });
    await _reloadComparisonData();
  }

  Future<void> _onPresetSelected(String preset) async {
    if (preset == 'custom') {
      await _pickDateB();
      return;
    }
    setState(() {
      _preset = preset;
      _dateB = computePresetDateB(dateA: _dateA, preset: preset);
    });
    await _reloadComparisonData();
  }

  Future<void> _onFactorySelected(int factoryId) async {
    setState(() {
      _selectedFactoryId = factoryId;

      _selectedUnit = _defaultUnit(_unitsForSelectedFactory);
    });
    await _reloadComparisonData();
  }

  void _onUnitSelected(FactoryUnit unit) {
    setState(() => _selectedUnit = unit.unitName);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text(
          '실적비교',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [Colors.white, Colors.grey[100]!],
          ),
        ),
        child: Column(
          children: [
            SizedBox(height: MediaQuery.of(context).padding.top + kToolbarHeight),
            if (_isLoading)
              const Expanded(child: LoadingIndicator())
            else if (_error != null)
              Expanded(child: Center(child: Text('오류: $_error')))
            else if (_factories.isEmpty)
              const Expanded(child: Center(child: Text('배정된 공장이 없습니다')))
            else ...[
              _buildFilterCard(),
              Expanded(child: _buildContentArea()),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFilterCard() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              SimpleDropdownButton<FactorySummary>(
                items: _factories,
                selectedItem:
                    _factories.firstWhere((f) => f.factoryId == _selectedFactoryId),
                labelOf: (f) => f.factoryName,
                onSelected: (f) => _onFactorySelected(f.factoryId),
              ),
              if (_unitsForSelectedFactory.isNotEmpty) ...[
                const SizedBox(width: 8),
                SimpleDropdownButton<FactoryUnit>(
                  items: _unitsForSelectedFactory,
                  selectedItem: _unitsForSelectedFactory
                      .firstWhere((u) => u.unitName == _selectedUnit),
                  labelOf: (u) => u.unitNickname ?? u.unitName,
                  onSelected: _onUnitSelected,
                ),
              ],
            ],
          ),
          const SizedBox(height: 10),
          ComparisonDateRow(
            dateALabel: _dateLabel(_dateA),
            dateBLabel: _dateLabel(_dateB),
            onTapDateA: _pickDateA,
            onTapDateB: _pickDateB,
          ),
          const SizedBox(height: 10),
          PillSelector(
            labels: const ['전년 비교', '전월 비교', '직접 선택'],
            selectedIndex: _presetOrder.indexOf(_preset),
            onSelected: (i) => _onPresetSelected(_presetOrder[i]),
            padding: EdgeInsets.zero,
          ),
        ],
      ),
    );
  }

  Widget _buildContentArea() {
    return Container(
      decoration: const BoxDecoration(
        color: Color(0xFFEFF0F4),
        border: Border(
          top: BorderSide(color: Color(0xFFB0B8C8), width: 2),
        ),
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment(0, -0.95),
          colors: [Color(0xFFDFE4F0), Color(0xFFEFF0F4)],
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: _isDataLoading
            ? const LoadingIndicator()
            : _dataError != null
                ? Center(child: Text('오류: $_dataError'))
                : _buildComparisonCard(),
      ),
    );
  }

  List<ProcessMetricRow> get _currentMetrics {
    final unit = _selectedUnit;
    if (unit == null) return const [];
    if (_period == 'day') {
      return groupDayMetrics(
        productionsA: _rawProductionsA,
        productionsB: _rawProductionsB,
        factoryId: _selectedFactoryId!,
        unit: unit,
        processNames: _processNameLookup,
        processIds: _processIdsForSelectedFactory,
      );
    }
    return groupCumulativeMetrics(
      summaryA: _summaryA,
      summaryB: _summaryB,
      unit: unit,
      processNames: _processNameLookup,
      processIds: _processIdsForSelectedFactory,
    );
  }

  double? _graphPercent(ProcessMetricRow row) {
    final (a, b) = _graphMetric == 'result' ? (row.resultA, row.resultB) : (row.amountA, row.amountB);
    return computeDiff(a, b).percent;
  }

  List<ProcessMetricRow> _sortedByGraphMetric(List<ProcessMetricRow> metrics) {
    final sorted = [...metrics];
    sorted.sort((x, y) {
      final px = _graphPercent(x);
      final py = _graphPercent(y);
      if (px == null && py == null) return 0;
      if (px == null) return 1;
      if (py == null) return -1;
      return py.compareTo(px);
    });
    return sorted;
  }

  Widget _buildGraphSection(List<ProcessMetricRow> metrics) {
    final items = metrics
        .map((row) => (name: row.processName, diff: computeDiff(
              _graphMetric == 'result' ? row.resultA : row.amountA,
              _graphMetric == 'result' ? row.resultB : row.amountB,
            )))
        .toList();

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '공정별 증감',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              SegmentedToggle(
                options: const ['실적', '금액'],
                values: const ['result', 'amount'],
                selected: _graphMetric,
                activeColor: Colors.green,
                onChanged: (value) => setState(() => _graphMetric = value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          for (final item in items) DivergingBarRow(processName: item.name, diff: item.diff),
        ],
      ),
    );
  }

  Widget _buildComparisonCard() {
    final metrics = _sortedByGraphMetric(_currentMetrics);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                '공정별 비교',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              SegmentedToggle(
                options: const ['당일', '누적'],
                values: const ['day', 'cumulative'],
                selected: _period,
                onChanged: (value) => setState(() => _period = value),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (metrics.isNotEmpty) ...[
            _buildGraphSection(metrics),
            const SizedBox(height: 14),
          ],
          if (metrics.isEmpty)
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 24),
              child: Center(child: Text('비교할 데이터가 없습니다')),
            )
          else
            ProcessComparisonTable(
              rows: metrics,
              showWip: _period == 'day',
              unitLabel: _selectedUnitLabel,
              dateALabel: _dateLabel(_dateA),
              dateBLabel: _dateLabel(_dateB),
            ),
        ],
      ),
    );
  }
}
