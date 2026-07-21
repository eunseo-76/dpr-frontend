import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/label_store.dart';
import 'package:dpr_frontend/core/utils/validators.dart';
import 'package:two_dimensional_scrollables/two_dimensional_scrollables.dart';
import 'package:dpr_frontend/core/widgets/confirm_dialog.dart';
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
  final double? wip;

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
    this.wip,
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
  late final List<TextEditingController> _wipControllers;
  late final List<String> _initialTexts;
  late final List<String> _initialWipTexts;
  bool _hasChanges = false;
  bool _isSaving = false;

  static const _rowHeight = 40.0;
  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  int get _columnCount => 5;
  int get _rowCount => 1 + widget.rows.length;

  @override
  void initState() {
    super.initState();
    _initialTexts = widget.rows.map((r) => _formatInitial(r.value)).toList();
    _initialWipTexts = widget.rows.map((r) => _formatInitial(r.wip)).toList();
    _controllers =
        _initialTexts.map((t) => TextEditingController(text: t)).toList();
    _wipControllers =
        _initialWipTexts.map((t) => TextEditingController(text: t)).toList();
    for (final c in [..._controllers, ..._wipControllers]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [..._controllers, ..._wipControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatInitial(double? value) {
    if (value == null) return '';
    return value == value.roundToDouble()
        ? value.toInt().toString()
        : value.toString();
  }

  void _onChanged() {
    bool changed = false;
    for (var i = 0; i < widget.rows.length; i++) {
      if (_controllers[i].text != _initialTexts[i] ||
          _wipControllers[i].text != _initialWipTexts[i]) {
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
      final key = '${row.processId}_${row.clientId}_${row.unitId}';
      final text = _controllers[i].text;
      final value = text.isEmpty && _initialTexts[i].isNotEmpty
          ? 0.0
          : double.tryParse(text);
      final wipText = _wipControllers[i].text;
      final wip = wipText.isEmpty && _initialWipTexts[i].isNotEmpty
          ? 0.0
          : double.tryParse(wipText);

      grouped.putIfAbsent(
        key,
        () => {
          'factoryId': row.factoryId,
          'processId': row.processId,
          'clientId': row.clientId,
          'unitId': row.unitId,
        },
      );

      if (row.shift == '주') {
        grouped[key]!['dayShift'] = value;
        grouped[key]!['wipDayShift'] = wip;
      } else {
        grouped[key]!['nightShift'] = value;
        grouped[key]!['wipNightShift'] = wip;
      }
    }

    final entries = <ProductionUpsertEntry>[];
    for (final g in grouped.values) {
      final dayShift = g['dayShift'] as double?;
      final nightShift = g['nightShift'] as double?;
      final wipDayShift = g['wipDayShift'] as double?;
      final wipNightShift = g['wipNightShift'] as double?;
      if (dayShift == null &&
          nightShift == null &&
          wipDayShift == null &&
          wipNightShift == null) {
        continue;
      }

      entries.add(ProductionUpsertEntry(
        factoryId: g['factoryId'] as int,
        processId: g['processId'] as int,
        clientId: g['clientId'] as int,
        unitId: g['unitId'] as int,
        dayShift: dayShift,
        nightShift: nightShift,
        wipDayShift: wipDayShift,
        wipNightShift: wipNightShift,
      ));
    }

    setState(() => _isSaving = true);
    try {
      await widget.onSave(entries);
    } catch (_) {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<bool> _confirmDismiss() async {
    if (!_hasChanges) return true;
    return showConfirmDialog(
      context,
      title: '변경사항이 있습니다',
      content: '저장하지 않고 나가시겠습니까?',
      confirmLabel: '나가기',
    );
  }

  (int, int)? _cellMerge(TableVicinity vicinity) {
    if (vicinity.row == 0) return null;
    final dataIndex = vicinity.row - 1;
    final row = widget.rows[dataIndex];

    if (vicinity.column == 0) {
      final start =
          widget.rows.indexWhere((r) => r.rowGroupId == row.rowGroupId);
      final span =
          widget.rows.where((r) => r.rowGroupId == row.rowGroupId).length;
      return (start + 1, span);
    }

    if (vicinity.column == 1) {
      final start = widget.rows.indexWhere(
          (r) => r.rowGroupId == row.rowGroupId && r.shift == row.shift);
      final span = widget.rows
          .where(
              (r) => r.rowGroupId == row.rowGroupId && r.shift == row.shift)
          .length;
      return (start + 1, span);
    }

    return null;
  }

  TableSpan _buildColumnSpan(int column) {
    final frac = switch (column) {
      0 => 0.24,
      1 => 0.10,
      2 => 0.13,
      3 => 0.265,
      _ => 0.265,
    };
    return TableSpan(
      extent: FractionalTableSpanExtent(frac),
      foregroundDecoration: column < _columnCount - 1
          ? const TableSpanDecoration(
              border:
                  TableSpanBorder(trailing: BorderSide(color: _borderColor)),
            )
          : null,
    );
  }

  TableSpan _buildRowSpan(int row) {
    return TableSpan(
      extent: const FixedTableSpanExtent(_rowHeight),
      backgroundDecoration: row == 0
          ? const TableSpanDecoration(color: _headerColor)
          : null,
      foregroundDecoration: const TableSpanDecoration(
        border: TableSpanBorder(trailing: BorderSide(color: _borderColor)),
      ),
    );
  }

  TableViewCell _buildCell(BuildContext context, TableVicinity vicinity) {
    final merge = _cellMerge(vicinity);

    Widget child;
    if (vicinity.row == 0) {
      final headers = [
        widget.rowLabelHeader,
        LabelStore.get('PRODUCTION_TABLE_HEADER_TYPE', '구분'),
        LabelStore.get('PRODUCTION_TABLE_HEADER_UNIT', '단위'),
        LabelStore.get('PRODUCTION_TABLE_HEADER_VALUE', '실적'),
        LabelStore.get('PRODUCTION_TABLE_HEADER_WIP', '재공'),
      ];
      child = Container(
        alignment: Alignment.center,
        padding: const EdgeInsets.symmetric(horizontal: 8),
        child: Text(
          headers[vicinity.column],
          textAlign: TextAlign.center,
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
        ),
      );
    } else {
      final dataIndex = vicinity.row - 1;
      final row = widget.rows[dataIndex];

      switch (vicinity.column) {
        case 0:
          child = Container(
            alignment: Alignment.centerLeft,
            padding: const EdgeInsets.symmetric(horizontal: 8),
            child: Text(row.rowGroupName, style: const TextStyle(fontSize: 13)),
          );
        case 1:
          child = Container(
            alignment: Alignment.center,
            child: Text(row.shift, style: const TextStyle(fontSize: 13)),
          );
        case 2:
          child = Container(
            alignment: Alignment.center,
            child: Text(row.unitName, style: const TextStyle(fontSize: 13)),
          );
        case 3:
          child = _inputCell(context, _controllers[dataIndex]);
        default:
          child = _inputCell(context, _wipControllers[dataIndex]);
      }
    }

    return TableViewCell(
      rowMergeStart: merge?.$1,
      rowMergeSpan: merge?.$2,
      child: child,
    );
  }

  Widget _inputCell(BuildContext context, TextEditingController controller) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
      child: Theme(
        data: Theme.of(context).copyWith(
          textSelectionTheme: const TextSelectionThemeData(
            selectionHandleColor: Colors.transparent,
          ),
        ),
        child: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [PositiveDecimalFormatter()],
          textAlign: TextAlign.center,
          style: const TextStyle(fontSize: 13),
          decoration: InputDecoration(
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
            hintText: '-',
            hintStyle: TextStyle(color: Colors.grey[400]),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: Colors.grey[300]!),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: const BorderSide(color: Colors.blue, width: 2),
            ),
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final tableHeight = _rowCount * _rowHeight;
    final maxTableHeight = MediaQuery.of(context).size.height * 0.5;

    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (didPop) return;
        final shouldPop = await _confirmDismiss();
        if (shouldPop && context.mounted) Navigator.pop(context);
      },
      child: AlertDialog(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        insetPadding: const EdgeInsets.symmetric(horizontal: 20),
        titlePadding: const EdgeInsets.fromLTRB(20, 16, 8, 0),
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    widget.title,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.close),
                  onPressed: () async {
                    final shouldPop = await _confirmDismiss();
                    if (shouldPop && context.mounted) Navigator.pop(context);
                  },
                ),
              ],
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: Colors.green.withValues(alpha: 0.1),
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.6),
                  width: 1.5,
                ),
                borderRadius: BorderRadius.circular(20),
                boxShadow: [
                  BoxShadow(
                    color: Colors.green.withValues(alpha: 0.15),
                    blurRadius: 8,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: Text(
                widget.date,
                style: const TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w600,
                  fontSize: 13,
                ),
              ),
            ),
          ],
        ),
        contentPadding: const EdgeInsets.fromLTRB(20, 16, 20, 0),
        content: SizedBox(
          width: double.maxFinite,
          height: tableHeight.clamp(0, maxTableHeight),
          child: ScrollConfiguration(
            behavior: ScrollConfiguration.of(context).copyWith(overscroll: false),
            child: TableView.builder(
              columnCount: _columnCount,
              rowCount: _rowCount,
              pinnedRowCount: 1,
              pinnedColumnCount: 1,
              columnBuilder: _buildColumnSpan,
              rowBuilder: _buildRowSpan,
              cellBuilder: (context, vicinity) => _buildCell(context, vicinity),
            ),
          ),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
        actions: [
          Row(
            children: [
              Expanded(
                child: SizedBox(
                  height: 48,
                  child: OutlinedButton(
                    onPressed: _isSaving
                        ? null
                        : () async {
                            final shouldPop = await _confirmDismiss();
                            if (shouldPop && context.mounted) {
                              Navigator.pop(context);
                            }
                          },
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
                    onPressed: _hasChanges && !_isSaving ? _save : null,
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
    );
  }
}
