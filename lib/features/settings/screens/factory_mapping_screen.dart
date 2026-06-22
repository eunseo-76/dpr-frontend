import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/models/master_data_entity.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/features/client/models/factory_client.dart';
import 'package:dpr_frontend/features/settings/models/factory_unit.dart';
import 'package:dpr_frontend/features/settings/services/factory_mapping_service.dart';
import 'package:dpr_frontend/features/utility/models/factory_process.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';
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

  int _selectedTabIndex = 0;

  // 현재 선택된 공장의 체크 상태 (편집 중인 상태)
  Set<int> _checkedProcessIds = {};
  Set<int> _checkedUnitIds = {};
  Set<int> _checkedClientIds = {};

  // 저장된 원래 상태 (취소 시 복원용)
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

  // 선택된 공장의 매핑 데이터로 체크 상태를 세팅
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

  void _onTabChanged(int index) {
    setState(() => _selectedTabIndex = index);
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
    final factoryId = _factories[_selectedTabIndex].id;

    setState(() => _isSaving = true);

    try {
      await Future.wait([
        _mappingService.syncProcesses(factoryId, _checkedProcessIds.toList()),
        _mappingService.syncUnits(factoryId, _checkedUnitIds.toList()),
        _mappingService.syncClients(factoryId, _checkedClientIds.toList()),
      ]);

      setState(() {
        _savedProcessIds = Set.from(_checkedProcessIds);
        _savedUnitIds = Set.from(_checkedUnitIds);
        _savedClientIds = Set.from(_checkedClientIds);
      });

      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text('저장되었습니다')));
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text('저장 실패: $e')));
      }
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
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 0,
              children: allItems.map((item) {
                return SizedBox(
                  width: 160,
                  child: CheckboxListTile(
                    title: Text(item.name, style: const TextStyle(fontSize: 14)),
                    value: checkedIds.contains(item.id),
                    onChanged: (checked) => onChanged(item.id, checked ?? false),
                    dense: true,
                    contentPadding: EdgeInsets.zero,
                    controlAffinity: ListTileControlAffinity.leading,
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        appBar: AppBar(title: const Text('공장별 항목 관리')),
        body: const LoadingIndicator(),
      );
    }

    if (_error != null) {
      return Scaffold(
        appBar: AppBar(title: const Text('공장별 항목 관리')),
        body: Center(child: Text('오류: $_error')),
      );
    }

    if (_factories.isEmpty) {
      return Scaffold(
        appBar: AppBar(title: const Text('공장별 항목 관리')),
        body: const Center(child: Text('등록된 공장이 없습니다')),
      );
    }

    return DefaultTabController(
      length: _factories.length,
      child: Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('공장별 항목 관리'),
          bottom: TabBar(
            isScrollable: true,
            onTap: _onTabChanged,
            tabs: _factories.map((f) => Tab(text: f.name)).toList(),
          ),
        ),
        body: ListView(
          padding: const EdgeInsets.all(16),
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
            const SizedBox(height: 16),
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
            const SizedBox(height: 16),
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
                  child: OutlinedButton(
                    onPressed: _onCancel,
                    child: const Text('취소'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilledButton(
                    onPressed: _hasChanges && !_isSaving ? _onSave : null,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('저장'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}