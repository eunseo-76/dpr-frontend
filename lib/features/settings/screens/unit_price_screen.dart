import 'package:dpr_frontend/core/constants/api_constants.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/utils/validators.dart';
import 'package:dpr_frontend/core/widgets/confirm_dialog.dart';
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
import 'package:dpr_frontend/core/widgets/wobble_effect.dart';
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

  Future<void> _onFactorySelected(int index) async {
    if (index == _selectedFactoryIndex) return;

    if (_hasChanges) {
      final confirmed = await showConfirmDialog(
        context,
        title: '변경사항이 있습니다',
        content: '저장하지 않고 다른 공장으로 이동하시겠습니까?\n수정한 내용은 사라집니다.',
        confirmLabel: '이동',
        isDestructive: true,
      );
      if (!confirmed) return;
    }

    setState(() {
      _selectedFactoryIndex = index;
      _selectedProcessIndex = 0;
    });
    _loadUnitPrices();
  }

  Future<void> _onProcessSelected(int index) async {
    if (index == _selectedProcessIndex) return;

    if (_hasChanges) {
      final confirmed = await showConfirmDialog(
        context,
        title: '변경사항이 있습니다',
        content: '저장하지 않고 다른 공정으로 이동하시겠습니까?\n수정한 내용은 사라집니다.',
        confirmLabel: '이동',
        isDestructive: true,
      );
      if (!confirmed) return;
    }

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
    final processes = _factories.isNotEmpty ? _currentProcesses : <FactoryProcess>[];
    final clients = _factories.isNotEmpty ? _currentClients : <FactoryClient>[];
    final units = _factories.isNotEmpty ? _currentUnits : <FactoryUnit>[];

    return Scaffold(
      extendBodyBehindAppBar: true,
      backgroundColor: Colors.transparent,
      appBar: AppBar(
        title: const Text('단가 관리', style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
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
                          : processes.isEmpty
                ? const FractionallySizedBox(
                    heightFactor: 0.5,
                    alignment: Alignment.topCenter,
                    child: Center(
                      child: Text(
                        '이 공장에 등록된 공정이 없습니다.\n[공장별 항목 관리] 메뉴에서 공정을 추가해주세요.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  )
                : clients.isEmpty && !_isPriceLoading
                    ? const FractionallySizedBox(
                        heightFactor: 0.5,
                        alignment: Alignment.topCenter,
                        child: Center(
                          child: Text(
                            '이 공장에 등록된 업체가 없습니다.\n[공장별 항목 관리] 메뉴에서 업체를 추가해주세요.',
                            textAlign: TextAlign.center,
                          ),
                        ),
                      )
                    : ListView(
                            padding: const EdgeInsets.fromLTRB(16, 16, 16, 16),
                            children: [
                              Row(
                                children: processes.asMap().entries.map((entry) {
                                  final isSelected = entry.key == _selectedProcessIndex;
                                  final isLast = entry.key == processes.length - 1;
                                  return Expanded(
                                    child: Padding(
                                      padding: EdgeInsets.only(right: isLast ? 0 : 2),
                                      child: GestureDetector(
                                        onTap: () => _onProcessSelected(entry.key),
                                        child: WobbleEffect(
                                          trigger: isSelected,
                                          child: Container(
                                          padding: const EdgeInsets.symmetric(vertical: 10),
                                          decoration: BoxDecoration(
                                            color: isSelected
                                                ? Colors.white
                                                : Colors.grey[200],
                                            borderRadius: const BorderRadius.only(
                                              topLeft: Radius.circular(10),
                                              topRight: Radius.circular(10),
                                            ),
                                          ),
                                          alignment: Alignment.center,
                                          child: Text(
                                            entry.value.processName,
                                            style: TextStyle(
                                              fontWeight: isSelected
                                                  ? FontWeight.w600
                                                  : FontWeight.normal,
                                              color: isSelected
                                                  ? Colors.blue
                                                  : Colors.grey[600],
                                              fontSize: 13,
                                            ),
                                          ),
                                        ),
                                        ),
                                      ),
                                    ),
                                  );
                                }).toList(),
                              ),
                              Container(
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.only(
                                    topLeft: _selectedProcessIndex == 0
                                        ? Radius.zero
                                        : const Radius.circular(12),
                                    topRight: const Radius.circular(12),
                                    bottomLeft: const Radius.circular(12),
                                    bottomRight: const Radius.circular(12),
                                  ),
                                ),
                                padding: const EdgeInsets.all(16),
                                child: AnimatedSwitcher(
                                  duration: const Duration(milliseconds: 250),
                                  child: _isPriceLoading
                                    ? const SizedBox(
                                        key: ValueKey('loading'),
                                        height: 120,
                                        child: LoadingIndicator(size: 90),
                                      )
                                    : Column(
                                        key: ValueKey(_selectedProcessIndex),
                                  children: [
                                    const Row(
                                      children: [
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '업체',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
                                        Expanded(
                                          flex: 2,
                                          child: Text(
                                            '기준단위',
                                            style: TextStyle(
                                              fontWeight: FontWeight.bold,
                                            ),
                                          ),
                                        ),
                                        SizedBox(width: 8),
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
                                              flex: 2,
                                              child: Text(client.clientName),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: LayoutBuilder(
                                                builder: (context, constraints) {
                                                  final selectedName = units
                                                      .firstWhere((u) => u.unitId == editing.unitId)
                                                      .unitName;
                                                  return PopupMenuButton<int>(
                                                    initialValue: editing.unitId,
                                                    onSelected: (value) =>
                                                        setState(() => editing.unitId = value),
                                                    constraints: BoxConstraints(
                                                      minWidth: constraints.maxWidth,
                                                      maxWidth: constraints.maxWidth,
                                                    ),
                                                    shape: RoundedRectangleBorder(
                                                      borderRadius: BorderRadius.circular(12),
                                                    ),
                                                    color: Colors.white,
                                                    elevation: 4,
                                                    position: PopupMenuPosition.under,
                                                    itemBuilder: (_) => units.map((u) =>
                                                      PopupMenuItem(
                                                        value: u.unitId,
                                                        height: 40,
                                                        child: Text(u.unitName, style: const TextStyle(fontSize: 14)),
                                                      ),
                                                    ).toList(),
                                                    child: InputDecorator(
                                                      decoration: InputDecoration(
                                                        isDense: true,
                                                        contentPadding: const EdgeInsets.symmetric(
                                                          horizontal: 12,
                                                          vertical: 8,
                                                        ),
                                                        border: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                                        ),
                                                        enabledBorder: OutlineInputBorder(
                                                          borderRadius: BorderRadius.circular(8),
                                                          borderSide: BorderSide(color: Colors.grey[300]!),
                                                        ),
                                                        suffixIcon: const Icon(Icons.keyboard_arrow_down, size: 20),
                                                        suffixIconConstraints: const BoxConstraints(
                                                          minWidth: 24,
                                                          minHeight: 24,
                                                        ),
                                                      ),
                                                      child: Text(selectedName, style: const TextStyle(fontSize: 14)),
                                                    ),
                                                  );
                                                },
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              flex: 2,
                                              child: TextField(
                                                controller:
                                                    editing.priceController,
                                                keyboardType:
                                                    TextInputType.number,
                                                inputFormatters: [PositiveDecimalFormatter()],
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
                              ),
                              if (!_isPriceLoading) ...[
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
                            ],
                          ),
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
