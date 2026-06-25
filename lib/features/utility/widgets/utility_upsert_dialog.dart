import 'package:flutter/material.dart';
import 'package:dpr_frontend/core/utils/validators.dart';
import 'package:dpr_frontend/core/widgets/confirm_dialog.dart';
import 'package:dpr_frontend/features/utility/models/utility_upsert_entry.dart';

class UtilityUpsertRow {
  final int factoryId;
  final int processId;
  final String label;
  final double? electricity;
  final double? water;

  UtilityUpsertRow({
    required this.factoryId,
    required this.processId,
    required this.label,
    required this.electricity,
    required this.water,
  });
}

class UtilityUpsertDialog extends StatefulWidget {
  final String title;
  final String date;
  final String rowLabelHeader;
  final List<UtilityUpsertRow> rows;
  final Future<void> Function(List<UtilityUpsertEntry> entries) onSave;

  const UtilityUpsertDialog({
    super.key,
    required this.title,
    required this.date,
    required this.rowLabelHeader,
    required this.rows,
    required this.onSave,
  });

  @override
  State<UtilityUpsertDialog> createState() => _UtilityUpsertDialogState();
}

class _UtilityUpsertDialogState extends State<UtilityUpsertDialog> {
  late final List<TextEditingController> _electricityControllers;
  late final List<TextEditingController> _waterControllers;
  late final List<String> _initialElectricityTexts;
  late final List<String> _initialWaterTexts;
  bool _hasChanges = false;
  bool _isSaving = false;

  static const _borderColor = Color(0xFFE0E0E0);
  static const _headerColor = Color(0xFFF5F5F5);

  @override
  void initState() {
    super.initState();
    _initialElectricityTexts =
        widget.rows.map((r) => _formatInitial(r.electricity)).toList();
    _initialWaterTexts =
        widget.rows.map((r) => _formatInitial(r.water)).toList();
    _electricityControllers = _initialElectricityTexts
        .map((t) => TextEditingController(text: t))
        .toList();
    _waterControllers =
        _initialWaterTexts.map((t) => TextEditingController(text: t)).toList();
    for (final c in [..._electricityControllers, ..._waterControllers]) {
      c.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final c in [..._electricityControllers, ..._waterControllers]) {
      c.dispose();
    }
    super.dispose();
  }

  String _formatInitial(double? value) {
    final v = value ?? 0;
    return v == v.roundToDouble() ? v.toInt().toString() : v.toString();
  }

  void _onChanged() {
    bool changed = false;
    for (var i = 0; i < widget.rows.length; i++) {
      if (_electricityControllers[i].text != _initialElectricityTexts[i] ||
          _waterControllers[i].text != _initialWaterTexts[i]) {
        changed = true;
        break;
      }
    }
    if (changed != _hasChanges) {
      setState(() => _hasChanges = changed);
    }
  }

  Future<void> _save() async {
    final entries = <UtilityUpsertEntry>[];
    for (var i = 0; i < widget.rows.length; i++) {
      final row = widget.rows[i];
      entries.add(UtilityUpsertEntry(
        factoryId: row.factoryId,
        processId: row.processId,
        electricity: double.tryParse(_electricityControllers[i].text) ?? 0,
        water: double.tryParse(_waterControllers[i].text) ?? 0,
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

  @override
  Widget build(BuildContext context) {
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
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                decoration: const BoxDecoration(
                  color: _headerColor,
                  border: Border(
                    top: BorderSide(color: _borderColor),
                    bottom: BorderSide(color: _borderColor),
                  ),
                ),
                child: Row(
                  children: [
                    _headerCell(widget.rowLabelHeader, flex: 2),
                    _headerCell('전기(Kwh)', flex: 2),
                    _headerCell('용수(t)', flex: 2, isLast: true),
                  ],
                ),
              ),
              Flexible(
                child: SingleChildScrollView(
                  child: Column(
                    children: [
                      for (var i = 0; i < widget.rows.length; i++)
                        Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom: BorderSide(color: _borderColor),
                            ),
                          ),
                          child: Row(
                            children: [
                              _labelCell(widget.rows[i].label, flex: 2),
                              _inputCell(_electricityControllers[i], flex: 2),
                              _inputCell(_waterControllers[i],
                                  flex: 2, isLast: true),
                            ],
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
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
                      style:
                          TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
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

  Widget _headerCell(String text,
          {required int flex, bool isLast = false}) =>
      Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(right: BorderSide(color: _borderColor)),
          ),
          child: Text(
            text,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
          ),
        ),
      );

  Widget _labelCell(String text, {required int flex}) => Expanded(
        flex: flex,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          decoration: const BoxDecoration(
            border: Border(right: BorderSide(color: _borderColor)),
          ),
          child: Text(text, style: const TextStyle(fontSize: 13)),
        ),
      );

  Widget _inputCell(TextEditingController controller,
          {required int flex, bool isLast = false}) =>
      Expanded(
        flex: flex,
        child: Container(
          decoration: BoxDecoration(
            border: isLast
                ? null
                : const Border(right: BorderSide(color: _borderColor)),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Theme(
            data: Theme.of(context).copyWith(
              textSelectionTheme: const TextSelectionThemeData(
                selectionHandleColor: Colors.transparent,
              ),
            ),
            child: TextField(
              controller: controller,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [PositiveDecimalFormatter()],
              textAlign: TextAlign.center,
              enableInteractiveSelection: true,
              style: const TextStyle(fontSize: 13),
              decoration: InputDecoration(
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 8,
                ),
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
        ),
      );
}
