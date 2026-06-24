import 'package:flutter/material.dart';
import 'package:dpr_frontend/features/utility/models/utility_upsert_entry.dart';

// 편집 팝업의 한 행 - scaffold 정보(factoryId, processId, label) + 현재 값
// label: 공장별 뷰 -> 공정명, 공정별 뷰 -> 공장명
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

// 카드 편집 팝업
// rowLabelHeader(공정/공장) + 전기(Kwh) + 용수(t) 입력 테이블
// 기존 값으로 prefill (없으면 0), 값이 하나도 바뀌지 않으면 저장 비활성화
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

  @override
  void initState() {
    super.initState();

    _initialElectricityTexts =
        widget.rows.map((r) => _formatInitial(r.electricity)).toList();
    _initialWaterTexts =
        widget.rows.map((r) => _formatInitial(r.water)).toList();

    _electricityControllers =
        _initialElectricityTexts.map((t) => TextEditingController(text: t)).toList();
    _waterControllers =
        _initialWaterTexts.map((t) => TextEditingController(text: t)).toList();

    for (final controller in [..._electricityControllers, ..._waterControllers]) {
      controller.addListener(_onChanged);
    }
  }

  @override
  void dispose() {
    for (final controller in [..._electricityControllers, ..._waterControllers]) {
      controller.dispose();
    }
    super.dispose();
  }

  // 0/null -> "0", 정수면 "300", 소수면 "2.5"
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
      // 버튼이 바뀌었을 때만 다시 빌드
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

  @override
  Widget build(BuildContext context) {
    return Dialog(
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
                    style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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
              columnWidths: const {
                0: FlexColumnWidth(2),
                1: FlexColumnWidth(1.5),
                2: FlexColumnWidth(1.5),
              },
              children: [
                TableRow(children: [
                  _headerCell(widget.rowLabelHeader),
                  _headerCell('전기(Kwh)'),
                  _headerCell('용수(t)'),
                ]),
                for (var i = 0; i < widget.rows.length; i++)
                  TableRow(children: [
                    _labelCell(widget.rows[i].label),
                    _inputCell(_electricityControllers[i]),
                    _inputCell(_waterControllers[i]),
                  ]),
              ],
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
          decoration: const InputDecoration(isDense: true, border: OutlineInputBorder()),
        ),
      );
}