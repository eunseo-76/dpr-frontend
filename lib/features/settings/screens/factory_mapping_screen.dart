import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/widgets/confirm_dialog.dart';
import 'package:dpr_frontend/core/models/master_data_entity.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/features/client/models/factory_client.dart';
import 'package:dpr_frontend/features/settings/models/factory_unit.dart';
import 'package:dpr_frontend/features/settings/services/factory_mapping_service.dart';
import 'package:dpr_frontend/features/utility/models/factory_process.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';
import 'package:dpr_frontend/core/widgets/pill_selector.dart';
import 'package:dpr_frontend/core/widgets/rounded_checkbox.dart';
import 'package:flutter/material.dart';

class FactoryMappingScreen extends StatefulWidget {
  const FactoryMappingScreen({super.key});

  @override
  State<FactoryMappingScreen> createState() => _FactoryMappingScreenState();
}

class _FactoryMappingScreenState extends State<FactoryMappingScreen> {
  final _mappingService = FactoryMappingService();
  final _factoryService = MasterDataService(
    endpoint: ApiConstants.factory_,
    idKey: 'factoryId',
  );
  final _processService = MasterDataService(
    endpoint: ApiConstants.process,
    idKey: 'processId',
  );
  final _unitService = MasterDataService(
    endpoint: ApiConstants.unit,
    idKey: 'unitId',
  );
  final _clientService = MasterDataService(
    endpoint: ApiConstants.client,
    idKey: 'clientId',
  );

  bool _isLoading = true;
  bool _isSaving = false;
  String? _error;

  List<MasterDataEntity> _factories = [];
  List<MasterDataEntity> _allProcesses = [];
  List<MasterDataEntity> _allUnits = [];
  List<MasterDataEntity> _allClients = [];

  List<FactoryProcess> _factoryProcesses = [];
  List<FactoryUnit> _factoryUnits = [];
  List<FactoryClient> _factoryClients = [];

  int _selectedFactoryIndex = 0;

  Set<int> _checkedProcessIds = {};
  Set<int> _checkedUnitIds = {};
  Set<int> _checkedClientIds = {};

  Set<int> _savedProcessIds = {};
  Set<int> _savedUnitIds = {};
  Set<int> _savedClientIds = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _factoryService.getAll(),
        _processService.getAll(),
        _unitService.getAll(),
        _clientService.getAll(),
        _mappingService.getFactoryProcesses(),
        _mappingService.getFactoryUnits(),
        _mappingService.getFactoryClients(),
      ]);

      setState(() {
        _factories = results[0] as List<MasterDataEntity>;
        _allProcesses = results[1] as List<MasterDataEntity>;
        _allUnits = results[2] as List<MasterDataEntity>;
        _allClients = results[3] as List<MasterDataEntity>;
        _factoryProcesses = results[4] as List<FactoryProcess>;
        _factoryUnits = results[5] as List<FactoryUnit>;
        _factoryClients = results[6] as List<FactoryClient>;
      });

      if (_factories.isNotEmpty) {
        _applyMappingForFactory(_factories[0].id);
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  void _applyMappingForFactory(int factoryId) {
    final processIds = _factoryProcesses
        .where((fp) => fp.factoryId == factoryId)
        .map((fp) => fp.processId)
        .toSet();
    final unitIds = _factoryUnits
        .where((fu) => fu.factoryId == factoryId)
        .map((fu) => fu.unitId)
        .toSet();
    final clientIds = _factoryClients
        .where((fc) => fc.factoryId == factoryId)
        .map((fc) => fc.clientId)
        .toSet();

    setState(() {
      _checkedProcessIds = Set.from(processIds);
      _checkedUnitIds = Set.from(unitIds);
      _checkedClientIds = Set.from(clientIds);
      _savedProcessIds = Set.from(processIds);
      _savedUnitIds = Set.from(unitIds);
      _savedClientIds = Set.from(clientIds);
    });
  }

  Future<void> _onFactorySelected(int index) async {
    if (index == _selectedFactoryIndex) return;

    if (_hasChanges) {
      final confirmed = await confirmDiscardChanges(
        context,
        content: '저장하지 않고 다른 공장으로 이동하시겠습니까?\n수정한 내용은 사라집니다.',
        confirmLabel: '이동',
      );
      if (!confirmed) return;
    }

    setState(() => _selectedFactoryIndex = index);
    _applyMappingForFactory(_factories[index].id);
  }

  bool get _hasChanges =>
      !_setEquals(_checkedProcessIds, _savedProcessIds) ||
      !_setEquals(_checkedUnitIds, _savedUnitIds) ||
      !_setEquals(_checkedClientIds, _savedClientIds);

  bool _setEquals(Set<int> a, Set<int> b) =>
      a.length == b.length && a.containsAll(b);

  void _onCancel() {
    setState(() {
      _checkedProcessIds = Set.from(_savedProcessIds);
      _checkedUnitIds = Set.from(_savedUnitIds);
      _checkedClientIds = Set.from(_savedClientIds);
    });
  }

  Future<void> _onSave() async {
    final factoryId = _factories[_selectedFactoryIndex].id;

    setState(() => _isSaving = true);

    try {
      await Future.wait([
        // 3개 동시 요청
        _mappingService.syncProcesses(factoryId, _checkedProcessIds.toList()),
        _mappingService.syncUnits(factoryId, _checkedUnitIds.toList()),
        _mappingService.syncClients(factoryId, _checkedClientIds.toList()),
      ]);

      setState(() {
        _savedProcessIds = Set.from(_checkedProcessIds);
        _savedUnitIds = Set.from(_checkedUnitIds);
        _savedClientIds = Set.from(_checkedClientIds);
      });

      if (mounted) showToast(context, '저장되었습니다', isError: false);
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e');
    } finally {
      setState(() => _isSaving = false);
    }
  }

  Widget _buildCheckboxSection({
    required String title,
    required List<MasterDataEntity> allItems,
    required Set<int> checkedIds,
    required void Function(int id, bool checked) onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 0,
            children: allItems.map((item) {
              final isChecked = checkedIds.contains(item.id);
              return SizedBox(
                width: 160,
                child: InkWell(
                  onTap: () => onChanged(item.id, !isChecked),
                  borderRadius: BorderRadius.circular(8),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        RoundedCheckbox(value: isChecked),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            item.name,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: isChecked ? FontWeight.w600 : FontWeight.normal,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = !_hasChanges || await confirmDiscardChanges(context);
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('공장별 항목 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                if (_factories.isNotEmpty)
                  PillSelector(
                    labels: _factories.map((f) => f.name).toList(),
                    selectedIndex: _selectedFactoryIndex,
                    onSelected: _onFactorySelected,
                  ),
              ],
            ),
          ),
          Expanded(
            child: Container(
              decoration: const BoxDecoration(
                color: Color(0xFFEFF0F4),
                border: Border(top: BorderSide(color: Color(0xFFB0B8C8), width: 2)),
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment(0, -0.95),
                  colors: [Color(0xFFDFE4F0), Color(0xFFEFF0F4)],
                ),
              ),
              child: _isLoading
                  ? const LoadingIndicator()
                  : _error != null
                      ? Center(child: Text('오류: $_error'))
                      : _factories.isEmpty
                          ? const Center(child: Text('등록된 공장이 없습니다'))
                          : ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
              children: [
                _buildCheckboxSection(
                  title: '공정',
                  allItems: _allProcesses,
                  checkedIds: _checkedProcessIds,
                  onChanged: (id, checked) {
                    setState(() {
                      if (checked) {
                        _checkedProcessIds.add(id);
                      } else {
                        _checkedProcessIds.remove(id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildCheckboxSection(
                  title: '단위',
                  allItems: _allUnits,
                  checkedIds: _checkedUnitIds,
                  onChanged: (id, checked) {
                    setState(() {
                      if (checked) {
                        _checkedUnitIds.add(id);
                      } else {
                        _checkedUnitIds.remove(id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 12),
                _buildCheckboxSection(
                  title: '업체',
                  allItems: _allClients,
                  checkedIds: _checkedClientIds,
                  onChanged: (id, checked) {
                    setState(() {
                      if (checked) {
                        _checkedClientIds.add(id);
                      } else {
                        _checkedClientIds.remove(id);
                      }
                    });
                  },
                ),
                const SizedBox(height: 24),
                Row(
                  children: [
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: OutlinedButton(
                          onPressed: _hasChanges ? _onCancel : null,
                          style: OutlinedButton.styleFrom(
                            foregroundColor: Colors.black87,
                            side: BorderSide(color: Colors.grey[300]!),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                          ),
                          child: const Text(
                            '취소',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: SizedBox(
                        height: 48,
                        child: ElevatedButton(
                          onPressed:
                              _hasChanges && !_isSaving ? _onSave : null,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black87,
                            foregroundColor: Colors.white,
                            disabledBackgroundColor: Colors.grey[300],
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(24),
                            ),
                            elevation: 0,
                          ),
                          child: _isSaving
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text(
                                  '저장',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            ),
          ),
        ],
      ),
    ),
    );
  }
}
