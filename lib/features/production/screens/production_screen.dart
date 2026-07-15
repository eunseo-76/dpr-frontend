import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/models/factory_summary.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/core/utils/shift_checker.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/utils/user_storage.dart';
import 'package:dpr_frontend/features/auth/services/user_service.dart';
import 'package:dpr_frontend/core/widgets/pill_selector.dart';
import 'package:dpr_frontend/features/settings/models/factory_shift.dart';
import 'package:dpr_frontend/features/settings/models/factory_unit.dart';
import 'package:dpr_frontend/features/settings/services/factory_mapping_service.dart';
import 'package:dpr_frontend/features/settings/services/factory_service.dart';
import 'package:dpr_frontend/core/widgets/calendar_picker.dart';
import 'package:dpr_frontend/core/widgets/date_navigator.dart';
import 'package:dpr_frontend/core/widgets/segmented_toggle.dart';
import 'package:dpr_frontend/features/client/models/factory_client.dart';
import 'package:dpr_frontend/features/client/services/client_service.dart';
import 'package:dpr_frontend/features/production/models/production.dart';
import 'package:dpr_frontend/features/production/models/production_overview.dart';
import 'package:dpr_frontend/features/production/services/production_service.dart';
import 'package:dpr_frontend/features/production/utils/production_grouping.dart';
import 'package:dpr_frontend/features/production/utils/production_overview_grouping.dart';
import 'package:dpr_frontend/features/production/utils/production_period_grouping.dart';
import 'package:dpr_frontend/features/production/utils/production_scaffold.dart';
import 'package:dpr_frontend/core/widgets/section_card.dart';
import 'package:dpr_frontend/features/production/widgets/production_card.dart';
import 'package:dpr_frontend/features/production/widgets/production_day_table.dart';
import 'package:dpr_frontend/features/production/widgets/production_overview_summary.dart';
import 'package:dpr_frontend/features/production/widgets/production_overview_table.dart';
import 'package:dpr_frontend/features/production/widgets/production_period_table.dart';
import 'package:dpr_frontend/features/unit/models/unit.dart';
import 'package:dpr_frontend/features/utility/models/factory_process.dart';
import 'package:dpr_frontend/features/utility/services/utility_service.dart';
import 'package:dpr_frontend/features/production/widgets/production_upsert_dialog.dart';
import 'package:dpr_frontend/features/utility/utils/utility_period_columns.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';
import 'package:dpr_frontend/core/widgets/wrench_refresh.dart';
import 'package:dpr_frontend/core/widgets/folder_tab_selector.dart';
import 'package:dpr_frontend/core/utils/label_store.dart';
import 'package:flutter/material.dart';

class ProductionScreen extends StatefulWidget {
  final VoidCallback? onGoToSettings;

  const ProductionScreen({super.key, this.onGoToSettings});

  @override
  State<ProductionScreen> createState() => _ProductionScreenState();
}

class _ProductionScreenState extends State<ProductionScreen> {
  String? _role;
  List<FactorySummary> _availableFactories = [];
  int _selectedFactoryIndex = 0;

  List<FactoryUnit> _allFactoryUnits = [];
  List<FactoryClient> _allFactoryClients = [];
  List<FactoryProcess> _allFactoryProcesses = [];
  List<Production> _allProductions = [];

  bool _isLoading = true;
  String? _error;
  String _groupBy = '공정별';
  String _selectedPeriod = '일';
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);
  bool _isSelectionMode = false;
  Set<int> _selectedRowGroupIds = {};

  FactoryShift? _factoryShift;

  int _selectedCardIndex = 0;

  DateTime? _overviewRangeStart;
  DateTime? _overviewRangeEnd;
  ProductionOverview? _overviewData;
  bool _overviewLoading = false;
  String? _overviewError;

  final _clientService = ClientService();
  final _utilityService = UtilityService();
  final _productionService = ProductionService();
  final _factoryService = FactoryService();
  final _factoryMappingService = FactoryMappingService();
  final _userService = UserService();

  int? get _selectedFactoryId => _availableFactories.isEmpty
      ? null
      : _availableFactories[_selectedFactoryIndex].factoryId;

  List<Unit> get _units => _allFactoryUnits
      .where((u) => u.factoryId == _selectedFactoryId)
      .map((u) => Unit(id: u.unitId, name: u.unitNickname ?? u.unitName))
      .toList();

  List<FactoryClient> get _factoryClients => _allFactoryClients
      .where((c) => c.factoryId == _selectedFactoryId)
      .toList();

  List<FactoryProcess> get _factoryProcesses => _allFactoryProcesses
      .where((p) => p.factoryId == _selectedFactoryId)
      .toList();

  List<Production> get _productions =>
      _allProductions.where((p) => p.factoryId == _selectedFactoryId).toList();

  bool get _canEdit => isEditAllowed(_factoryShift, _selectedDate);
  bool get _showAmount => _role != 'STAFF';
  bool get _hasMasterData =>
      _factoryProcesses.isNotEmpty &&
      _factoryClients.isNotEmpty &&
      _units.isNotEmpty;

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
    final picked = await showCalendarPicker(context, d);
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

  Future<void> _onOverviewCalendarTap() async {
    final initial = (_overviewRangeStart != null && _overviewRangeEnd != null)
        ? DateTimeRange(start: _overviewRangeStart!, end: _overviewRangeEnd!)
        : null;
    final picked = await showCalendarRangePicker(context, initial);
    if (picked != null) {
      setState(() {
        _overviewRangeStart = picked.start;
        _overviewRangeEnd = picked.end;
      });
      _loadOverview();
    }
  }

  String _overviewDisplayLabel() {
    if (_overviewRangeStart == null || _overviewRangeEnd == null) {
      return '기간을 선택하세요';
    }
    String fmt(DateTime d) =>
        '${d.year}.${d.month.toString().padLeft(2, '0')}.${d.day.toString().padLeft(2, '0')}';
    return '${fmt(_overviewRangeStart!)} ~ ${fmt(_overviewRangeEnd!)}';
  }

  void _navigateOverviewRange(int direction) {
    final start = _overviewRangeStart;
    final end = _overviewRangeEnd;
    if (start == null || end == null) return;

    final spanDays = end.difference(start).inDays + 1;
    setState(() {
      _overviewRangeStart = start.add(Duration(days: direction * spanDays));
      _overviewRangeEnd = end.add(Duration(days: direction * spanDays));
    });
    _loadOverview();
  }

  Future<void> _loadOverview() async {
    final factoryId = _selectedFactoryId;
    if (factoryId == null ||
        _overviewRangeStart == null ||
        _overviewRangeEnd == null) {
      return;
    }
    setState(() {
      _overviewLoading = true;
      _overviewError = null;
    });
    try {
      final data = await _productionService.getProductionOverview(
        factoryId: factoryId,
        dateFrom: _dateStr(_overviewRangeStart!),
        dateTo: _dateStr(_overviewRangeEnd!),
      );
      setState(() => _overviewData = data);
    } catch (e) {
      setState(() => _overviewError = e.toString());
    } finally {
      setState(() => _overviewLoading = false);
    }
  }

  Future<void> _loadAll() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      await _userService.refreshUserInfo();
      final role = await UserStorage.getRole();
      final factories = role == 'OWNER'
          ? (await MasterDataService(endpoint: ApiConstants.factory_, idKey: 'factoryId')
                  .getAll())
              .map((e) => FactorySummary(factoryId: e.id, factoryName: e.name))
              .toList()
          : await UserStorage.getFactories();

      setState(() {
        _role = role;
        _availableFactories = factories;
        _selectedFactoryIndex = 0;
      });

      if (factories.isEmpty) return;

      final labelsFuture = LabelStore.load();
      final results = await Future.wait([
        _factoryMappingService.getFactoryUnits(),
        _clientService.getFactoryClients(),
        _utilityService.getFactoryProcesses(),
        _productionService.getProductionList(
          date: _selectedDate,
          periodType: _periodTypeMap[_selectedPeriod]!,
        ),
      ]);
      final factoryShift = await _factoryService.getFactoryShift(factories.first.factoryId);
      await labelsFuture;
      setState(() {
        _allFactoryUnits = results[0] as List<FactoryUnit>;
        _allFactoryClients = results[1] as List<FactoryClient>;
        _allFactoryProcesses = results[2] as List<FactoryProcess>;
        _allProductions = results[3] as List<Production>;
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
      setState(() => _allProductions = productions);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _onFactorySelected(int index) {
    if (index == _selectedFactoryIndex) return;
    _exitSelectionMode();
    setState(() {
      _selectedFactoryIndex = index;
      _selectedCardIndex = 0;
    });
    _factoryService.getFactoryShift(_availableFactories[index].factoryId).then((shift) {
      if (mounted) setState(() => _factoryShift = shift);
    });
    if (_selectedPeriod == '전체보기') _loadOverview();
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
    final factoryId = _selectedFactoryId;
    if (factoryId == null) return;

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
        wip: rowScaffold.shift == '주'
            ? production?.wipDayShift
            : production?.wipNightShift,
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
                if (_availableFactories.length > 1)
                  Align(
                    alignment: Alignment.centerLeft,
                    child: PillSelector(
                      labels: _availableFactories.map((f) => f.factoryName).toList(),
                      selectedIndex: _selectedFactoryIndex,
                      onSelected: _onFactorySelected,
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 5),
                    ),
                  ),
                Padding(
                  padding: const EdgeInsets.only(top: 5, bottom: 12),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (_selectedPeriod != '전체보기') ...[
                            SegmentedToggle(
                              options: const ['공정별', '업체별'],
                              selected: _groupBy,
                              onChanged: (value) {
                                _exitSelectionMode();
                                setState(() {
                                  _groupBy = value;
                                  _selectedCardIndex = 0;
                                });
                              },
                            ),
                            const SizedBox(width: 12),
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
                            const SizedBox(width: 12),
                          ],
                          SegmentedToggle(
                            options: const ['일', '전체보기'],
                            selected: _selectedPeriod,
                            activeColor: Colors.green,
                            onChanged: (period) {
                              _exitSelectionMode();
                              setState(() {
                                _selectedPeriod = period;
                                if (period == '전체보기' &&
                                    (_overviewRangeStart == null ||
                                        _overviewRangeEnd == null)) {
                                  final d = DateTime.parse(_selectedDate);
                                  final monday =
                                      d.subtract(Duration(days: d.weekday - 1));
                                  _overviewRangeStart = monday;
                                  _overviewRangeEnd =
                                      monday.add(const Duration(days: 6));
                                }
                              });
                              if (period == '전체보기') {
                                _loadOverview();
                              } else {
                                _loadProductions();
                              }
                            },
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                DateNavigator(
                  label: _selectedPeriod == '전체보기'
                      ? _overviewDisplayLabel()
                      : _displayLabel(),
                  onPrevious: _selectedPeriod == '전체보기'
                      ? () => _navigateOverviewRange(-1)
                      : () => _navigateDate(-1),
                  onNext: _selectedPeriod == '전체보기'
                      ? () => _navigateOverviewRange(1)
                      : () => _navigateDate(1),
                  onCalendarTap: _selectedPeriod == '전체보기'
                      ? _onOverviewCalendarTap
                      : _onCalendarTap,
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
              child: _selectedPeriod == '전체보기'
                  ? _buildOverviewSection()
                  : _isLoading
                      ? const LoadingIndicator()
                      : _error != null
                          ? Center(child: Text('오류: $_error'))
                          : _availableFactories.isEmpty
                              ? _buildNoFactoryState()
                              : !_hasMasterData
                                  ? _buildEmptyState()
                                  : WrenchRefresh(
                                      onRefresh: _loadProductions,
                                      child: _buildDayView(),
                                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNoFactoryState() {
    final isOwner = _role == 'OWNER';
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.factory_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            isOwner ? '등록된 공장이 없습니다' : '배정된 공장이 없습니다. 관리자에게 문의하세요',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          if (isOwner && widget.onGoToSettings != null) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onGoToSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text('설정으로 이동'),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    final canGoToSettings = widget.onGoToSettings != null;
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.settings_outlined, size: 48, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            canGoToSettings
                ? '공정, 단위, 업체를 먼저 설정해주세요'
                : '관리자에게 설정을 요청하세요',
            style: TextStyle(fontSize: 15, color: Colors.grey[600]),
          ),
          if (canGoToSettings) ...[
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: widget.onGoToSettings,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.black87,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                elevation: 0,
              ),
              child: const Text('설정으로 이동'),
            ),
          ],
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
    final periodGroups = groupProductionsForPeriod(
      _productions,
      scaffold,
      columns,
      _groupBy,
      showAmount: _showAmount,
    );
    final rowLabelHeader = _groupBy == '공정별'
        ? LabelStore.get('PRODUCTION_TABLE_HEADER_CLIENT', '업체')
        : LabelStore.get('PRODUCTION_TABLE_HEADER_PROCESS', '공정');

    final columnDates = _selectedPeriod == '주'
        ? columns.map((c) => c.dates.first).toList()
        : null;

    if (periodGroups.isEmpty) return const SizedBox.shrink();
    final selectedIndex =
        _selectedCardIndex < periodGroups.length ? _selectedCardIndex : 0;
    final group = periodGroups[selectedIndex];
    final cardTitle = _groupBy == '공정별'
        ? '${group.groupName} 공정'
        : group.groupName;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 80),
      child: FolderTabSelector(
        labels: periodGroups.map((g) => g.groupName).toList(),
        selectedIndex: selectedIndex,
        onSelected: (index) => setState(() => _selectedCardIndex = index),
        child: ProductionCard(
          key: ValueKey(group.groupId),
          wrapInCard: false,
          title: cardTitle,
          units: _units,
          sumAmounts: _groupBy == '업체별',
          footer: ProductionCardFooter(
            dailyByUnit: group.dailySumByUnit,
            cumulativeByUnit: group.cumulativeSumByUnit,
            amountByUnit: _showAmount ? group.amountByUnit : null,
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
        ),
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
    final dayGroups = groupProductionsForDay(
      _productions,
      scaffold,
      _groupBy,
      showAmount: _showAmount,
    );
    final rowLabelHeader = _groupBy == '공정별'
        ? LabelStore.get('PRODUCTION_TABLE_HEADER_CLIENT', '업체')
        : LabelStore.get('PRODUCTION_TABLE_HEADER_PROCESS', '공정');

    if (dayGroups.isEmpty) return const SizedBox.shrink();
    final selectedIndex =
        _selectedCardIndex < dayGroups.length ? _selectedCardIndex : 0;
    final group = dayGroups[selectedIndex];
    final cardTitle = _groupBy == '공정별'
        ? '${group.groupName} 공정'
        : group.groupName;

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 80),
      child: FolderTabSelector(
        labels: dayGroups.map((g) => g.groupName).toList(),
        selectedIndex: selectedIndex,
        onSelected: (index) => setState(() => _selectedCardIndex = index),
        child: ProductionCard(
          key: ValueKey(group.groupId),
          wrapInCard: false,
          title: cardTitle,
          units: _units,
          onEditTap: _isSelectionMode || !_canEdit
              ? null
              : () {
                  if (!_hasMasterData) {
                    showToast(context, '공정, 단위, 업체가 모두 설정되어야 입력할 수 있습니다');
                    return;
                  }
                  _openUpsertDialog(
                    group: group,
                    groupScaffold: scaffold
                        .firstWhere((g) => g.groupId == group.groupId),
                    rowLabelHeader: rowLabelHeader,
                  );
                },
          sumAmounts: _groupBy == '업체별',
          footer: ProductionCardFooter(
            dailyByUnit: group.dailySumByUnit,
            cumulativeByUnit: group.cumulativeSumByUnit,
            amountByUnit: _showAmount ? group.amountByUnit : null,
            cumulativeAmountByUnit: _showAmount ? group.cumulativeAmountByUnit : null,
          ),
          table: ProductionDayTable(
            rowLabelHeader: rowLabelHeader,
            rows: group.rows,
            selectionMode: _isSelectionMode,
            selectedRowGroupIds: _selectedRowGroupIds,
            onRowGroupLongPress: null, // 삭제 기능 비활성화
            onRowGroupTap: _toggleSelection,
          ),
        ),
      ),
    );
  }

  Widget _buildOverviewSection() {
    if (_availableFactories.isEmpty) return _buildNoFactoryState();

    if (_overviewRangeStart == null || _overviewRangeEnd == null) {
      return Center(
        child: Text(
          '상단 캘린더 아이콘을 눌러 기간을 선택하세요',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }
    if (_overviewLoading) return const LoadingIndicator();
    if (_overviewError != null) {
      return Center(child: Text('오류: $_overviewError'));
    }

    final data = _overviewData;
    if (data == null || data.rows.isEmpty) {
      return Center(
        child: Text(
          '선택한 기간에 데이터가 없습니다',
          style: TextStyle(fontSize: 14, color: Colors.grey[600]),
        ),
      );
    }

    return _buildOverviewView(data);
  }

  Widget _buildOverviewView(ProductionOverview data) {
    final clientNames = {
      for (final c in _factoryClients) c.clientId: c.clientNickname ?? c.clientName,
    };
    final processNames = {
      for (final p in _factoryProcesses) p.processId: p.processNickname ?? p.processName,
    };
    final unitNames = {for (final u in _units) u.id: u.name};

    final unitOrder = _units.map((u) => u.id).toList();
    final pivotData = buildOverviewPivotRows(
      data.rows,
      clientNames: clientNames,
      processNames: processNames,
      unitNames: unitNames,
      unitOrder: unitOrder,
    );
    final summaryEntries = buildProcessSummaryDisplay(
      data.processSummary,
      processNames: processNames,
      unitNames: unitNames,
      unitOrder: unitOrder,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 80),
      child: SectionCard(
        title: _availableFactories[_selectedFactoryIndex].factoryName,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            ProductionOverviewSummary(entries: summaryEntries),
            const SizedBox(height: 12),
            ProductionOverviewTable(
              rows: pivotData.rows,
              unitColumns: pivotData.unitColumns,
            ),
          ],
        ),
      ),
    );
  }
}