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
  String _selectedDate = '2026.05.01';

  final _unitService = UnitService();
  final _productionService = ProductionService();

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    try {
      final factoryId = await UserStorage.getFactoryId();

      final results = await Future.wait([
        _unitService.getUnitList(factoryId: factoryId),
        _productionService.getProductionList(),
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
            onPeriodChanged: (period) => setState(() => _selectedPeriod = period),
          ),
          DateNavigation(
            date: _selectedDate,
            onPrevious: () {},
            onNext: () {},
            onCalendarTap: () {},
          ),
          ViewToggle(
            isProcessView: _isProcessView,
            onChanged: (value) => setState(() => _isProcessView = value),
          ),
          Expanded(
            child: ProductionTable(
              units: _units,
              productions: _productions,
              isProcessView: _isProcessView,
            ),
          ),
        ],
      ),
    );
  }
}
