import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/models/master_data_entity.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/features/client/models/factory_client.dart';
import 'package:dpr_frontend/features/settings/models/factory_unit.dart';
import 'package:dpr_frontend/features/settings/models/unit_price.dart';
import 'package:dpr_frontend/features/settings/services/factory_mapping_service.dart';
import 'package:dpr_frontend/features/settings/services/unit_price_service.dart';
import 'package:dpr_frontend/features/utility/models/factory_process.dart';
import 'package:dpr_frontend/core/widgets/loading_indicator.dart';
import 'package:dpr_frontend/core/widgets/pill_selector.dart';
import 'package:flutter/material.dart';

class UnitPriceScreen extends StatefulWidget {
  const UnitPriceScreen({super.key});

  @override
  State<UnitPriceScreen> createState() => _UnitPriceScreenState();
}

class _UnitPriceScreenState extends State<UnitPriceScreen> {
  final _mappingService = FactoryMappingService();
  final _unitPriceService = UnitPriceService();
  final _factoryService = MasterDataService(
    endpoint: ApiConstants.factory_,
    idKey: 'factoryId',
  );

  bool _isLoading = true;
  bool _isPriceLoading = false;
  String? _error;

  List<MasterDataEntity> _factories = [];
  List<FactoryProcess> _factoryProcesses = [];
  List<FactoryClient> _factoryClients = [];
  List<FactoryUnit> _factoryUnits = [];

  int _selectedFactoryIndex = 0;
  int _selectedProcessIndex = 0;

  List<UnitPrice> _unitPrices = [];
  Map<int, _EditingEntry> _editingEntries = {};

  @override
  void initState() {
    super.initState();
    _loadAll();
  }

  int get _currentFactoryId => _factories[_selectedFactoryIndex].id;

  List<FactoryProcess> get _currentProcesses =>
      _factoryProcesses
          .where((fp) => fp.factoryId == _currentFactoryId)
          .toList();

  int get _currentProcessId =>
      _currentProcesses[_selectedProcessIndex].processId;

  List<FactoryClient> get _currentClients =>
      _factoryClients
          .where((fc) => fc.factoryId == _currentFactoryId)
          .toList();

  List<FactoryUnit> get _currentUnits =>
      _factoryUnits.where((fu) => fu.factoryId == _currentFactoryId).toList();

  Future<void> _loadAll() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await Future.wait([
        _factoryService.getAll(),
        _mappingService.getFactoryProcesses(),
        _mappingService.getFactoryClients(),
        _mappingService.getFactoryUnits(),
      ]);

      setState(() {
        _factories = results[0] as List<MasterDataEntity>;
        _factoryProcesses = results[1] as List<FactoryProcess>;
        _factoryClients = results[2] as List<FactoryClient>;
        _factoryUnits = results[3] as List<FactoryUnit>;
      });

      if (_factories.isNotEmpty && _currentProcesses.isNotEmpty) {
        await _loadUnitPrices();
      }
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isLoading = false);
    }
  }

  Future<void> _loadUnitPrices() async {
    if (_currentProcesses.isEmpty) return;

    setState(() => _isPriceLoading = true);

    try {
      final prices = await _unitPriceService.getUnitPrices(
        _currentFactoryId,
        _currentProcessId,
      );
      setState(() {
        _unitPrices = prices;
        _buildEditingEntries();
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _isPriceLoading = false);
    }
  }

  void _buildEditingEntries() {
    for (final entry in _editingEntries.values) {
      entry.priceController.dispose();
    }

    final newEntries = <int, _EditingEntry>{};
    final units = _currentUnits;
    if (units.isEmpty) {
      _editingEntries = newEntries;
      return;
    }

    for (final client in _currentClients) {
      final existing =
          _unitPrices
              .where((up) => up.clientId == client.clientId)
              .firstOrNull;

      if (existing != null) {
        final priceText =
            existing.price == existing.price.toInt()
                ? existing.price.toInt().toString()
                : existing.price.toString();
        newEntries[client.clientId] = _EditingEntry(
          unitId: existing.unitId,
          priceText: priceText,
        );
      } else {
        newEntries[client.clientId] = _EditingEntry(
          unitId: units.first.unitId,
          priceText: '0',
        );
      }
    }

    _editingEntries = newEntries;
  }

  bool get _hasChanges {
    for (final client in _currentClients) {
      final editing = _editingEntries[client.clientId];
      if (editing == null) continue;

      final existing =
          _unitPrices
              .where((up) => up.clientId == client.clientId)
              .firstOrNull;

      if (existing != null) {
        final currentPrice =
            double.tryParse(editing.priceController.text) ?? 0;
        if (editing.unitId != existing.unitId ||
            currentPrice != existing.price) {
          return true;
        }
      } else {
        final currentPrice =
            double.tryParse(editing.priceController.text) ?? 0;
        if (currentPrice != 0) return true;
      }
    }
    return false;
  }

  void _onFactorySelected(int index) {
    setState(() {
      _selectedFactoryIndex = index;
      _selectedProcessIndex = 0;
    });
    _loadUnitPrices();
  }

  void _onProcessSelected(int index) {
    setState(() => _selectedProcessIndex = index);
    _loadUnitPrices();
  }

  Future<void> _onSave() async {
    final entries =
        _editingEntries.entries
            .map(
              (e) => {
                'clientId': e.key,
                'unitId': e.value.unitId,
                'price':
                    double.tryParse(e.value.priceController.text) ?? 0,
              },
            )
            .toList();

    setState(() => _isPriceLoading = true);

    try {
      await _unitPriceService.saveUnitPrices(
        _currentFactoryId,
        _currentProcessId,
        entries,
      );
      if (mounted) showToast(context, '저장되었습니다', isError: false);
      await _loadUnitPrices();
    } catch (e) {
      if (mounted) showToast(context, '저장 실패: $e');
      setState(() => _isPriceLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('단가 관리'),
          backgroundColor: Colors.grey[100],
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const LoadingIndicator(),
      );
    }

    if (_error != null) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('단가 관리'),
          backgroundColor: Colors.grey[100],
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: Center(child: Text('오류: $_error')),
      );
    }

    if (_factories.isEmpty) {
      return Scaffold(
        backgroundColor: Colors.grey[100],
        appBar: AppBar(
          title: const Text('단가 관리'),
          backgroundColor: Colors.grey[100],
          elevation: 0,
          scrolledUnderElevation: 0,
        ),
        body: const Center(child: Text('등록된 공장이 없습니다')),
      );
    }

    final processes = _currentProcesses;
    final clients = _currentClients;
    final units = _currentUnits;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        title: const Text('단가 관리'),
        backgroundColor: Colors.grey[100],
        elevation: 0,
        scrolledUnderElevation: 0,
      ),
      body: Column(
        children: [
          PillSelector(
            labels: _factories.map((f) => f.name).toList(),
            selectedIndex: _selectedFactoryIndex,
            onSelected: _onFactorySelected,
          ),
          if (processes.isNotEmpty)
            PillSelector(
              labels: processes.map((p) => p.processName).toList(),
              selectedIndex: _selectedProcessIndex,
              onSelected: _onProcessSelected,
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            ),
          Expanded(
            child: _isPriceLoading
                ? const LoadingIndicator()
                : processes.isEmpty
                    ? const Center(
                        child: Text(
                          '이 공장에 등록된 공정이 없습니다.\n[공장별 항목 관리] 메뉴에서 공정을 추가해주세요.',
                          textAlign: TextAlign.center,
                        ),
                      )
                    : clients.isEmpty
                        ? const Center(
                            child: Text(
                              '이 공장에 등록된 업체가 없습니다.\n[공장별 항목 관리] 메뉴에서 업체를 추가해주세요.',
                              textAlign: TextAlign.center,
                            ),
                          )
                        : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: Column(
                                  children: [
                                    const Row(
                                      children: [
                                        Expanded(
                                          flex: 3,
                                          child: Text(
                                            '업체',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '기준단위',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '단가',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                    const Divider(),
                                    ...clients.map((client) {
                                      final editing =
                                          _editingEntries[client.clientId];
                                      if (editing == null) {
                                        return const SizedBox.shrink();
                                      }

                                      return Padding(
                                        padding: const EdgeInsets.symmetric(
                                          vertical: 4,
                                        ),
                                        child: Row(
                                          children: [
                                            Expanded(
                                              flex: 3,
                                              child: Text(client.clientName),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: DropdownButton<int>(
                                                value: editing.unitId,
                                                isExpanded: true,
                                                underline: const SizedBox(),
                                                items: units
                                                    .map(
                                                      (u) => DropdownMenuItem(
                                                        value: u.unitId,
                                                        child:
                                                            Text(u.unitName),
                                                      ),
                                                    )
                                                    .toList(),
                                                onChanged: (value) {
                                                  if (value != null) {
                                                    setState(
                                                      () =>
                                                          editing.unitId =
                                                              value,
                                                    );
                                                  }
                                                },
                                              ),
                                            ),
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller:
                                                    editing.priceController,
                                                keyboardType:
                                                    TextInputType.number,
                                                onChanged: (_) =>
                                                    setState(() {}),
                                                decoration:
                                                    const InputDecoration(
                                                  isDense: true,
                                                  contentPadding:
                                                      EdgeInsets.symmetric(
                                                    horizontal: 8,
                                                    vertical: 8,
                                                  ),
                                                  border:
                                                      OutlineInputBorder(),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      );
                                    }),
                                  ],
                                ),
                              ),
                              const SizedBox(height: 24),
                              Row(
                                children: [
                                  Expanded(
                                    child: SizedBox(
                                      height: 48,
                                      child: OutlinedButton(
                                        onPressed: () => _loadUnitPrices(),
                                        style: OutlinedButton.styleFrom(
                                          foregroundColor: Colors.black87,
                                          side: BorderSide(
                                            color: Colors.grey[300]!,
                                          ),
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
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
                                            _hasChanges ? _onSave : null,
                                        style: ElevatedButton.styleFrom(
                                          backgroundColor: Colors.black87,
                                          foregroundColor: Colors.white,
                                          disabledBackgroundColor:
                                              Colors.grey[300],
                                          shape: RoundedRectangleBorder(
                                            borderRadius:
                                                BorderRadius.circular(24),
                                          ),
                                          elevation: 0,
                                        ),
                                        child: const Text(
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
        ],
      ),
    );
  }

  @override
  void dispose() {
    for (final entry in _editingEntries.values) {
      entry.priceController.dispose();
    }
    super.dispose();
  }
}

class _EditingEntry {
  int unitId;
  final TextEditingController priceController;

  _EditingEntry({required this.unitId, required String priceText})
      : priceController = TextEditingController(text: priceText);
}
