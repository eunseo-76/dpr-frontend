import 'package:dpr_frontend/core/utils/number_format.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/widgets/simple_data_table.dart';
import 'package:dpr_frontend/features/utility/models/factory_process.dart';
import 'package:dpr_frontend/features/utility/models/utility.dart';
import 'package:dpr_frontend/features/utility/models/utility_summary.dart';
import 'package:dpr_frontend/features/utility/services/utility_service.dart';
import 'package:dpr_frontend/features/utility/utils/factory_process_scaffold.dart';
import 'package:dpr_frontend/features/utility/utils/utility_grouping.dart';
import 'package:dpr_frontend/features/utility/utils/utility_period_columns.dart';
import 'package:dpr_frontend/features/utility/utils/utility_period_grouping.dart';
import 'package:dpr_frontend/core/widgets/date_navigator.dart';
import 'package:dpr_frontend/core/widgets/segmented_toggle.dart';
import 'package:dpr_frontend/features/utility/widgets/utility_card.dart';
import 'package:dpr_frontend/features/utility/widgets/utility_period_table.dart';
import 'package:dpr_frontend/features/utility/widgets/utility_upsert_dialog.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';
import 'package:flutter/material.dart';

class UtilityScreen extends StatefulWidget {
  const UtilityScreen({super.key});

  @override
  State<UtilityScreen> createState() => _UtilityScreenState();
}

class _UtilityScreenState extends State<UtilityScreen> {
  List<Utility> _utilities = [];
  List<UtilitySummary> _summaries = [];
  List<FactoryProcess> _factoryProcesses = [];
  bool _isLoading = true;
  String? _error;
  String _groupBy = '공장별';
  String _selectedPeriod = '일';
  String _selectedDate = DateTime.now().toIso8601String().substring(0, 10);
  bool _isSelectionMode = false;
  Set<int> _selectedIds = {};

  final _utilityService = UtilityService();

  static const _periodTypeMap = {
    '일': 'DAY',
    '주': 'WEEK',
    '월': 'MONTH',
    '년': 'YEAR',
  };

  static const _groupByMap = {
    '공장별': 'FACTORY',
    '공정별': 'PROCESS',
  };

  @override
  void initState() {
    super.initState();
    _loadFactoryProcesses();
    _loadData();
  }

  // 공장-공정 매핑 (날짜와 무관, 한 번만 불러오면 됨)
  Future<void> _loadFactoryProcesses() async {
    try {
      final factoryProcesses = await _utilityService.getFactoryProcesses();
      setState(() => _factoryProcesses = factoryProcesses);
    } catch (e) {
      setState(() => _error = e.toString());
    }
  }

  Future<void> _loadData() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _utilityService.getUtilityList(
          date: _selectedDate,
          periodType: _periodTypeMap[_selectedPeriod]!,
        ),
        _utilityService.getUtilitySummary(
          groupBy: _groupByMap[_groupBy]!,
          date: _selectedDate,
        ),
      ]);

      setState(() {
        _utilities = results[0] as List<Utility>;
        _summaries = results[1] as List<UtilitySummary>;
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  // groupId로 누적합계를 찾는다. 없으면 0 (데이터 없는 그룹)
  UtilitySummary? _summaryFor(int groupId) {
    for (final summary in _summaries) {
      if (summary.groupId == groupId) return summary;
    }
    return null;
  }

  DateTime get _selectedDateTime => DateTime.parse(_selectedDate);

  // 주 보기에서 사용할 월~일 7개 날짜('yyyy-MM-dd')
  List<String> _weekDateColumns() {
    final monday = _selectedDateTime.subtract(
      Duration(days: _selectedDateTime.weekday - 1),
    );
    return List.generate(7, (i) {
      final date = monday.add(Duration(days: i));
      return date.toIso8601String().substring(0, 10);
    });
  }

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

  // long-press: 선택 모드 진입 + 첫 항목 선택
  void _enterSelectionMode(int utilityId) {
    setState(() {
      _isSelectionMode = true;
      _selectedIds = {utilityId};
    });
  }

  // 선택 모드 중 행 탭: 선택 토글. 마지막 항목을 해제하면 선택 모드 종료
  void _toggleSelection(int utilityId) {
    setState(() {
      if (_selectedIds.contains(utilityId)) {
        _selectedIds.remove(utilityId);
      } else {
        _selectedIds.add(utilityId);
      }
      if (_selectedIds.isEmpty) _isSelectionMode = false;
    });
  }

  void _exitSelectionMode() {
    setState(() {
      _isSelectionMode = false;
      _selectedIds = {};
    });
  }

  // 휴지통 아이콘 -> 확인 다이얼로그 -> 삭제
  Future<void> _confirmDelete() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('삭제'),
        content: Text('선택한 ${_selectedIds.length}개 항목을 삭제할까요?'),
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

    setState(() => _isLoading = true);
    try {
      await _utilityService.deleteUtilities(_selectedIds.toList());
      _exitSelectionMode();
      _loadData();
    } catch (e) {
      setState(() => _isLoading = false);
      if (mounted) showToast(context, '삭제 실패: $e');
    }
  }

  // 카드 편집 아이콘 -> 팝업. group(실적 데이터)과 groupScaffold(factoryId/processId)를
  // 같은 순서로 묶어 UtilityUpsertRow 목록을 만든다.
  void _openUpsertDialog({
    required UtilityGroup group,
    required GroupScaffold groupScaffold,
    required String rowLabelHeader,
  }) {
    final rows = List.generate(group.rows.length, (i) {
      final data = group.rows[i];
      final rowScaffold = groupScaffold.rows[i];
      return UtilityUpsertRow(
        factoryId: rowScaffold.factoryId,
        processId: rowScaffold.processId,
        label: data.label,
        electricity: data.electricity,
        water: data.water,
      );
    });

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => UtilityUpsertDialog(
        title: '${group.groupName} 편집',
        date: _selectedDate.replaceAll('-', '.'),
        rowLabelHeader: rowLabelHeader,
        rows: rows,
        onSave: (entries) async {
          try {
            await _utilityService.upsertUtilities(
              date: _selectedDate,
              entries: entries,
            );
            if (dialogContext.mounted) Navigator.pop(dialogContext);
            _loadData();
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
    final scaffold = buildScaffold(_factoryProcesses, _groupBy);

    Widget content;
    if (_isLoading) {
      content = const LoadingIndicator();
    } else if (_error != null) {
      content = Center(child: Text('오류: $_error'));
    } else if (_selectedPeriod == '주') {
      final dateColumns = _weekDateColumns();
      final columnLabels = dateColumns
          .map((date) => DateTime.parse(date).day.toString().padLeft(2, '0'))
          .toList();
      final groups = groupUtilitiesByPeriod(_utilities, scaffold, dateColumns);
      final rowLabelHeader = _groupBy == '공장별' ? '공정' : '공장';
      content = ListView(
        padding: const EdgeInsets.all(8),
        children: groups
            .map((group) => UtilityCard(
                  title: group.groupName,
                  cumulativeElectricity:
                      _summaryFor(group.groupId)?.electricitySum ?? 0,
                  cumulativeWater: _summaryFor(group.groupId)?.waterSum ?? 0,
                  table: UtilityPeriodTable(
                    rowLabelHeader: rowLabelHeader,
                    columnLabels: columnLabels,
                    electricityRows: group.electricityRows,
                    waterRows: group.waterRows,
                    columnDates: dateColumns,
                    onDateTap: (date) {
                      setState(() {
                        _selectedDate = date;
                        _selectedPeriod = '일';
                      });
                      _loadData();
                    },
                  ),
                ))
            .toList(),
      );
    } else if (_selectedPeriod == '월') {
      final date = _selectedDateTime;
      final columns = monthPeriodColumns(date.year, date.month);
      final columnLabels = columns.map((c) => c.label).toList();
      final groups = groupUtilitiesByColumns(_utilities, scaffold, columns);
      final rowLabelHeader = _groupBy == '공장별' ? '공정' : '공장';
      content = ListView(
        padding: const EdgeInsets.all(8),
        children: groups
            .map((group) => UtilityCard(
                  title: group.groupName,
                  cumulativeElectricity:
                      _summaryFor(group.groupId)?.electricitySum ?? 0,
                  cumulativeWater: _summaryFor(group.groupId)?.waterSum ?? 0,
                  table: UtilityPeriodTable(
                    rowLabelHeader: rowLabelHeader,
                    columnLabels: columnLabels,
                    electricityRows: group.electricityRows,
                    waterRows: group.waterRows,
                  ),
                ))
            .toList(),
      );
    } else if (_selectedPeriod == '년') {
      final columns = yearPeriodColumns(_selectedDateTime.year);
      final columnLabels = columns.map((c) => c.label).toList();
      final groups = groupUtilitiesByColumns(_utilities, scaffold, columns);
      final rowLabelHeader = _groupBy == '공장별' ? '공정' : '공장';
      content = ListView(
        padding: const EdgeInsets.all(8),
        children: groups
            .map((group) => UtilityCard(
                  title: group.groupName,
                  cumulativeElectricity:
                      _summaryFor(group.groupId)?.electricitySum ?? 0,
                  cumulativeWater: _summaryFor(group.groupId)?.waterSum ?? 0,
                  table: UtilityPeriodTable(
                    rowLabelHeader: rowLabelHeader,
                    columnLabels: columnLabels,
                    electricityRows: group.electricityRows,
                    waterRows: group.waterRows,
                  ),
                ))
            .toList(),
      );
    } else {
      final groups = groupUtilities(_utilities, scaffold);
      final rowLabelHeader = _groupBy == '공장별' ? '공정' : '공장';
      content = ListView(
        padding: const EdgeInsets.all(8),
        children: groups
            .map((group) => UtilityCard(
                  title: group.groupName,
                  cumulativeElectricity:
                      _summaryFor(group.groupId)?.electricitySum ?? 0,
                  cumulativeWater: _summaryFor(group.groupId)?.waterSum ?? 0,
                  onEditTap: _isSelectionMode
                      ? null
                      : () => _openUpsertDialog(
                            group: group,
                            groupScaffold: scaffold
                                .firstWhere((g) => g.groupId == group.groupId),
                            rowLabelHeader: rowLabelHeader,
                          ),
                  table: SimpleDataTable(
                    headers: const ['구분', '전기(Kwh)', '용수(t)'],
                    rows: group.rows
                        .map((r) => [
                              r.label,
                              r.electricity == null
                                  ? '-'
                                  : formatNumber(r.electricity!),
                              r.water == null ? '-' : formatNumber(r.water!),
                            ])
                        .toList(),
                    rowIds: group.rows.map((r) => r.utilityId).toList(),
                    selectionMode: _isSelectionMode,
                    selectedIds: _selectedIds,
                    onRowLongPress: _enterSelectionMode,
                    onRowTap: _toggleSelection,
                  ),
                ))
            .toList(),
      );
    }

    return Scaffold(
      appBar: _isSelectionMode
          ? AppBar(
              backgroundColor: Colors.deepPurple,
              foregroundColor: Colors.white,
              leading: IconButton(
                icon: const Icon(Icons.close),
                onPressed: _exitSelectionMode,
              ),
              title: Text('${_selectedIds.length}개 선택됨'),
              actions: [
                IconButton(
                  icon: const Icon(Icons.delete_outline),
                  onPressed: _confirmDelete,
                ),
              ],
            )
          : null,
      body: SafeArea(
        child: Column(
          children: [
            SegmentedToggle(
              options: const ['공장별', '공정별'],
              selected: _groupBy,
              onChanged: (value) {
                _exitSelectionMode();
                setState(() => _groupBy = value);
                _loadData();
              },
            ),
            SegmentedToggle(
              options: const ['일', '주', '월', '년'],
              selected: _selectedPeriod,
              onChanged: (value) {
                _exitSelectionMode();
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
