import 'package:flutter/material.dart';
import 'package:dpr_frontend/features/production/models/production_upsert_entry.dart';

class ProductionUpsertRow {
  final int factoryId;
  final int processId;
  final int clientId;
  final int unitId;
  final int rowGroupId;
  final String rowGroupName;
  final String shift;
  final String unitName;
  final double? value;

  ProductionUpsertRow({
    required this.factoryId,
    required this.processId,
    required this.clientId,
    required this.unitId,
    required this.rowGroupId,
    required this.rowGroupName,
    required this.shift,
    required this.unitName,
    this.value,
  });
}

class ProductionUpsertDialog extends StatefulWidget {
  final String title;
  final String date;
  final String rowLabelHeader;
  final List<ProductionUpsertRow> rows;
  final Future<void> Function(List<ProductionUpsertEntry> entries) onSave;

  const ProductionUpsertDialog({
    super.key,
    required this.title,
    required this.date,
    required this.rowLabelHeader,
    required this.rows,
    required this.onSave,
  });

  @override
  State<ProductionUpsertDialog> createState() => _ProductionUpsertDialogState();
}

class _ProductionUpsertDialogState extends State<ProductionUpsertDialog> {
  late final List<TextEditingController> _controllers;
  late final List<String> _initialTexts;
  bool _hasChanges = false;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _initialTexts = widget.rows.map((r) => _formatInitial(r.value)).toList();
    _controllers =
        _initialTexts.map((t) => TextEditingController(text: t)).toList();
    for (final c in _controllers) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in _controllers) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatInitial(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble() ? value.toInt().toString() : value.toString();
  }

  void _onChanged() {
    bool changed = false;
    for (var i = 0; i < widget.rows.length; i++) {
      if (_controllers[i].text != _initialTexts[i]) {
        changed = true;
        break;
      }
    }
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  Future<void> _save() async {
    final grouped = <String, Map<String, dynamic>>{};

    for (var i = 0; i < widget.rows.length; i++) {
      final row = widget.rows[i];
      final key = '${row.clientId}_${row.unitId}';
      final value = double.tryParse(_controllers[i].text);

      grouped.putIfAbsent(key, () => {
        'factoryId': row.factoryId,
        'processId': row.processId,
        'clientId': row.clientId,
        'unitId': row.unitId,
      });

      if (row.shift == '주') {
        grouped[key]!['dayShift'] = value;
      } else {
        grouped[key]!['nightShift'] = value;
      }
    }

    final entries = <ProductionUpsertEntry>[];
    for (final g in grouped.values) {
      final dayShift = g['dayShift'] as double?;
      final nightShift = g['nightShift'] as double?;
      if (dayShift == null && nightShift == null) continue;

      entries.add(ProductionUpsertEntry(
        factoryId: g['factoryId'] as int,
        processId: g['processId'] as int,
        clientId: g['clientId'] as int,
        unitId: g['unitId'] as int,
        dayShift: dayShift,
        nightShift: nightShift,
      ));
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(entries);
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  bool _showGroupLabel(int i) {
    if (i == 0) return true;
    return widget.rows[i].rowGroupId != widget.rows[i - 1].rowGroupId;
  }

  bool _showShiftLabel(int i) {
    if (i == 0) return true;
    final curr = widget.rows[i];
    final prev = widget.rows[i - 1];
    return curr.rowGroupId != prev.rowGroupId || curr.shift != prev.shift;
  }

  static const _columnWidths = <int, TableColumnWidth>{
    0: FlexColumnWidth(2),
    1: FlexColumnWidth(1),
    2: FlexColumnWidth(1.2),
    3: FlexColumnWidth(1.5),
  };

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.7,
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Text(
                      widget.title,
                      style: const TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(widget.date),
              const SizedBox(height: 12),
              Table(
                columnWidths: _columnWidths,
                children: [
                  TableRow(children: [
                    _headerCell(widget.rowLabelHeader),
                    _headerCell('구분'),
                    _headerCell('단위'),
                    _headerCell('값'),
                  ]),
                ],
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Table(
                    columnWidths: _columnWidths,
                    children: [
                      for (var i = 0; i < widget.rows.length; i++)
                        TableRow(children: [
                          _labelCell(_showGroupLabel(i)
                              ? widget.rows[i].rowGroupName
                              : ''),
                          _labelCell(
                              _showShiftLabel(i) ? widget.rows[i].shift : ''),
                          _labelCell(widget.rows[i].unitName),
                          _inputCell(_controllers[i]),
                        ]),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: _isSaving ? null : () => Navigator.pop(context),
                    child: const Text('취소'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    onPressed: _hasChanges && !_isSaving ? _save : null,
                    child: _isSaving
                        ? const SizedBox(
                            width: 20, height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Text('저장'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _headerCell(String text) => Padding(
        padding: const EdgeInsets.all(8),
        child: Text(text, style: const TextStyle(fontWeight: FontWeight.bold)),
      );

  Widget _labelCell(String text) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text),
      );

  Widget _inputCell(TextEditingController controller) => Padding(
        padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          textAlign: TextAlign.center,
          decoration:
              const InputDecoration(isDense: true, border: OutlineInputBorder()),
        ),
      );
}