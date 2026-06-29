import 'package:dpr_frontend/core/utils/shift_checker.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/features/settings/models/factory_shift.dart';
import 'package:dpr_frontend/features/settings/services/factory_service.dart';
import 'package:dpr_frontend/core/widgets/date_navigator.dart';
import 'package:dpr_frontend/core/widgets/segmented_toggle.dart';
import 'package:dpr_frontend/features/client/models/factory_client.dart';
import 'package:dpr_frontend/features/client/services/client_service.dart';
import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/services/production_service.dart';
import 'package:dpr_frontend/features/production/utils/production_grouping.dart';
import 'package:dpr_frontend/features/production/utils/production_period_grouping.dart';
import 'package:dpr_frontend/features/production/utils/production_scaffold.dart';
import 'package:dpr_frontend/features/production/widgets/production_card.dart';
import 'package:dpr_frontend/features/production/widgets/production_day_table.dart';
import 'package:dpr_frontend/features/production/widgets/production_period_table.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';
import 'package:dpr_frontend/features/unit/services/unit_service.dart';
import 'package:dpr_frontend/features/utility/models/factory_process.dart';
import 'package:dpr_frontend/features/utility/services/utility_service.dart';
import 'package:dpr_frontend/features/production/widgets/production_upsert_dialog.dart';
import 'package:dpr_frontend/features/utility/utils/utility_period_columns.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';
import 'package:dpr_frontend/core/widgets/wrench_refresh.dart';
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
  bool _isSelectionMode = false;
  Set<int> _selectedRowGroupIds = {};

  FactoryShift? _factoryShift;

  final _unitService = UnitService();
  final _clientService = ClientService();
  final _utilityService = UtilityService();
  final _productionService = ProductionService();
  final _factoryService = FactoryService();

  bool get _canEdit => isEditAllowed(_factoryShift, _selectedDate);

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
      final factoryShift = factoryId != null
          ? await _factoryService.getFactoryShift(factoryId)
          : null;
      setState(() {
        _units = results[0] as List<Unit>;
        _factoryClients = results[1] as List<FactoryClient>;
        _factoryProcesses = results[2] as List<FactoryProcess>;
        _productions = results[3] as List<Production>;
        _factoryShift = factoryShift;
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


  void _enterSelectionMode(int rowGroupId) {
    setState(() {
      _isSelectionMode = true;
      _selectedRowGroupIds = {rowGroupId};
    });
  }

  void _toggleSelection(int rowGroupId) {
    setState(() {
      if (_selectedRowGroupIds.contains(rowGroupId)) {
        _selectedRowGroupIds.remove(rowGroupId);
      } else {
        _selectedRowGroupIds.add(rowGroupId);
      }
      if (_selectedRowGroupIds.isEmpty) _isSelectionMode = false;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedRowGroupIds = {};
    });
  }

  Future<void> _confirmDelete() async {
    final idsToDelete = _productions
        .where((p) {
          final rowGroupId =
              _groupBy == '공정별' ? p.clientId : p.processId;
          return _selectedRowGroupIds.contains(rowGroupId);
        })
        .map((p) => p.productionId)
        .toSet()
        .toList();

    if (idsToDelete.isEmpty) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제'),
        content: Text('선택한 ${_selectedRowGroupIds.length}개 그룹의 데이터를 삭제할까요?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() { _isLoading = true; _error = null; });
    try {
      await _productionService.deleteProductions(idsToDelete);
      _exitSelectionMode();
      _loadProductions();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) showToast(context, '삭제 실패: $e');
    }
  }

  void _openUpsertDialog({
    required ProductionDayGroup group,
    required ProductionGroupScaffold groupScaffold,
    required String rowLabelHeader,
  }) {
    final factoryId = _factoryProcesses.first.factoryId;

    final rows = groupScaffold.rows.map((rowScaffold) {
      final match = _productions.where((p) =>
          (_groupBy == '공정별' ? p.clientId : p.processId) ==
              rowScaffold.rowGroupId &&
          p.unitId == rowScaffold.unitId &&
          (_groupBy == '공정별' ? p.processId : p.clientId) ==
              groupScaffold.groupId);
      final production = match.isEmpty ? null : match.first;

      return ProductionUpsertRow(
        factoryId: factoryId,
        processId: _groupBy == '공정별'
            ? groupScaffold.groupId
            : rowScaffold.rowGroupId,
        clientId: _groupBy == '공정별'
            ? rowScaffold.rowGroupId
            : groupScaffold.groupId,
        unitId: rowScaffold.unitId,
        rowGroupId: rowScaffold.rowGroupId,
        rowGroupName: rowScaffold.rowGroupName,
        shift: rowScaffold.shift,
        unitName: rowScaffold.unitName,
        value: rowScaffold.shift == '주'
            ? production?.dayShift
            : production?.nightShift,
      );
    }).toList();

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => ProductionUpsertDialog(
        title: '${group.groupName} 일일 실적 수정',
        date: _selectedDate.replaceAll('-', '.'),
        rowLabelHeader: rowLabelHeader,
        rows: rows,
        onSave: (entries) async {
          try {
            await _productionService.upsertProductions(
              date: _selectedDate,
              entries: entries,
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            _loadProductions();
          } catch (e) {
            if (dialogContext.mounted) showToast(dialogContext, '저장 실패: $e');
            rethrow;
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text('${_selectedRowGroupIds.length}개 선택됨'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _confirmDelete,
                ),
              ],
            )
          : AppBar(
              title: const Text(
                '생산실적',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
              backgroundColor: Colors.transparent,
              elevation: 0,
              scrolledUnderElevation: 0,
            ),
      body: Column(
        children: [
          Container(
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
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  child: Row(
                    children: [
                      SegmentedToggle(
                        options: const ['공정별', '업체별'],
                        selected: _groupBy,
                        onChanged: (value) {
                          _exitSelectionMode();
                          setState(() => _groupBy = value);
                        },
                      ),
                      const Spacer(),
                      Container(
                        width: 1.5,
                        height: 24,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(1),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.1),
                              blurRadius: 4,
                              offset: const Offset(0, 1),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      SegmentedToggle(
                        options: const ['일', '주', '월', '년'],
                        selected: _selectedPeriod,
                        activeColor: Colors.green,
                        onChanged: (period) {
                          _exitSelectionMode();
                          setState(() => _selectedPeriod = period);
                          _loadProductions();
                        },
                      ),
                    ],
                  ),
                ),
                DateNavigator(
                  label: _displayLabel(),
                  onPrevious: () => _navigateDate(-1),
                  onNext: () => _navigateDate(1),
                  onCalendarTap: _onCalendarTap,
                ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEFF0F4),
                border: Border(
                  top: BorderSide(color: Color(0xFFB0B8C8), width: 2),
                ),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment(0, -0.95),
                  colors: [
                    Color(0xFFDFE4F0),
                    Color(0xFFEFF0F4),
                  ],
                ),
              ),
              child: _isLoading
                  ? const LoadingIndicator()
                  : _error != null
                      ? Center(child: Text('오류: $_error'))
                      : WrenchRefresh(
                          onRefresh: _loadProductions,
                          child: _selectedPeriod == '일'
                              ? _buildDayView()
                              : _buildPeriodView(),
                        ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPeriodView() {
    final scaffold = buildProductionScaffold(
      factoryProcesses: _factoryProcesses,
      factoryClients: _factoryClients,
      units: _units,
      groupBy: _groupBy,
    );

    final date = DateTime.parse(_selectedDate);
    final List<PeriodColumn> columns;
    switch (_selectedPeriod) {
      case '주':
        columns = weekPeriodColumns(_selectedDate);
      case '월':
        columns = monthPeriodColumns(date.year, date.month);
      case '년':
        columns = yearPeriodColumns(date.year);
      default:
        return const SizedBox.shrink();
    }

    final columnLabels = columns.map((c) => c.label).toList();
    final columnTooltips = columns.map((c) => c.tooltip).toList();
    final periodGroups =
        groupProductionsForPeriod(_productions, scaffold, columns, _groupBy);
    final rowLabelHeader = _groupBy == '공정별' ? '업체' : '공정';

    final columnDates = _selectedPeriod == '주'
        ? columns.map((c) => c.dates.first).toList()
        : null;

    return ListView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 80),
      children: periodGroups.map((group) {
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
          table: ProductionPeriodTable(
            rowLabelHeader: rowLabelHeader,
            columnLabels: columnLabels,
            rows: group.rows,
            columnTooltips: columnTooltips,
            columnDates: columnDates,
            onDateTap: columnDates != null
                ? (date) {
                    setState(() {
                      _selectedDate = date;
                      _selectedPeriod = '일';
                    });
                    _loadProductions();
                  }
                : null,
          ),
        );
      }).toList(),
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
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 80),
      children: dayGroups.map((group) {
        final cardTitle = _groupBy == '공정별'
            ? '${group.groupName} 공정'
            : group.groupName;

        return ProductionCard(
          title: cardTitle,
          units: _units,
          onEditTap: _isSelectionMode || !_canEdit
              ? null
              : () => _openUpsertDialog(
                    group: group,
                    groupScaffold: scaffold
                        .firstWhere((g) => g.groupId == group.groupId),
                    rowLabelHeader: rowLabelHeader,
                  ),
          footer: ProductionCardFooter(
            dailyByUnit: group.dailySumByUnit,
            cumulativeByUnit: group.cumulativeSumByUnit,
          ),
          table: ProductionDayTable(
            rowLabelHeader: rowLabelHeader,
            rows: group.rows,
            selectionMode: _isSelectionMode,
            selectedRowGroupIds: _selectedRowGroupIds,
            onRowGroupLongPress: _enterSelectionMode,
            onRowGroupTap: _toggleSelection,
          ),
        );
      }).toList(),
    );
  }
}