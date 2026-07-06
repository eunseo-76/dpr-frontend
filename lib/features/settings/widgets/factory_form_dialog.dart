import 'package:dpr_frontend/core/models/master_data_entity.dart';
import 'package:dpr_frontend/core/services/master_data_service.dart';
import 'package:dpr_frontend/core/utils/toast.dart';
import 'package:dpr_frontend/core/widgets/form_dialog.dart';
import 'package:dpr_frontend/core/widgets/shake_field.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void showFactoryFormDialog(
  BuildContext context, {
  MasterDataEntity? item,
  required MasterDataService service,
  required VoidCallback onRefresh,
}) {
  showDialog(
    context: context,
    builder: (_) => _FactoryFormDialog(item: item, service: service, onRefresh: onRefresh),
  );
}

class _FactoryFormDialog extends StatefulWidget {
  final MasterDataEntity? item;
  final MasterDataService service;
  final VoidCallback onRefresh;

  const _FactoryFormDialog({this.item, required this.service, required this.onRefresh});

  @override
  State<_FactoryFormDialog> createState() => _FactoryFormDialogState();
}

class _FactoryFormDialogState extends State<_FactoryFormDialog> {
  late final TextEditingController _name, _nickname, _address, _email, _phone;
  late final TextEditingController _dayStartH, _dayStartM;
  late final TextEditingController _dayEndH, _dayEndM;
  late final TextEditingController _nightStartH, _nightStartM;
  late final TextEditingController _nightEndH, _nightEndM;

  final _dayStartMFocus = FocusNode();
  final _dayEndMFocus = FocusNode();
  final _nightStartMFocus = FocusNode();
  final _nightEndMFocus = FocusNode();

  final _dayStartHShake = GlobalKey<ShakeFieldState>();
  final _dayStartMShake = GlobalKey<ShakeFieldState>();
  final _dayEndHShake = GlobalKey<ShakeFieldState>();
  final _dayEndMShake = GlobalKey<ShakeFieldState>();
  final _nightStartHShake = GlobalKey<ShakeFieldState>();
  final _nightStartMShake = GlobalKey<ShakeFieldState>();
  final _nightEndHShake = GlobalKey<ShakeFieldState>();
  final _nightEndMShake = GlobalKey<ShakeFieldState>();
  final _nameShake = GlobalKey<ShakeFieldState>();

  bool _hasNightShift = false;
  bool _isSaving = false;

  late final String _initName, _initNickname, _initAddress, _initEmail, _initPhone;
  late final bool _initHasNightShift;
  late final String _initDayStartH, _initDayStartM, _initDayEndH, _initDayEndM;
  late final String _initNightStartH, _initNightStartM, _initNightEndH, _initNightEndM;

  String _hh(String? v) => (v != null && v.length >= 2) ? v.substring(0, 2) : '';
  String _mm(String? v) => (v != null && v.length >= 5) ? v.substring(3, 5) : '';

  String? _timeValue(TextEditingController h, TextEditingController m) {
    final hh = h.text.trim();
    final mm = m.text.trim();
    if (hh.isEmpty && mm.isEmpty) return null;
    return '${hh.padLeft(2, '0')}:${mm.padLeft(2, '0')}:00';
  }

  @override
  void initState() {
    super.initState();
    final d = widget.item?.data;
    _name = TextEditingController(text: d?['name'] as String? ?? '');
    _nickname = TextEditingController(text: d?['nickname'] as String? ?? '');
    _address = TextEditingController(text: d?['address'] as String? ?? '');
    _email = TextEditingController(text: d?['email'] as String? ?? '');
    _phone = TextEditingController(text: d?['phone'] as String? ?? '');
    _hasNightShift = d?['hasNightShift'] as bool? ?? false;

    final ds = d?['dayShiftStart'] as String?;
    final de = d?['dayShiftEnd'] as String?;
    final ns = d?['nightShiftStart'] as String?;
    final ne = d?['nightShiftEnd'] as String?;

    _dayStartH = TextEditingController(text: _hh(ds));
    _dayStartM = TextEditingController(text: _mm(ds));
    _dayEndH = TextEditingController(text: _hh(de));
    _dayEndM = TextEditingController(text: _mm(de));
    _nightStartH = TextEditingController(text: _hh(ns));
    _nightStartM = TextEditingController(text: _mm(ns));
    _nightEndH = TextEditingController(text: _hh(ne));
    _nightEndM = TextEditingController(text: _mm(ne));

    _initName = _name.text; _initNickname = _nickname.text;
    _initAddress = _address.text; _initEmail = _email.text; _initPhone = _phone.text;
    _initHasNightShift = _hasNightShift;
    _initDayStartH = _dayStartH.text; _initDayStartM = _dayStartM.text;
    _initDayEndH = _dayEndH.text; _initDayEndM = _dayEndM.text;
    _initNightStartH = _nightStartH.text; _initNightStartM = _nightStartM.text;
    _initNightEndH = _nightEndH.text; _initNightEndM = _nightEndM.text;
  }

  @override
  void dispose() {
    _name.dispose(); _nickname.dispose(); _address.dispose();
    _email.dispose(); _phone.dispose();
    _dayStartH.dispose(); _dayStartM.dispose();
    _dayEndH.dispose(); _dayEndM.dispose();
    _nightStartH.dispose(); _nightStartM.dispose();
    _nightEndH.dispose(); _nightEndM.dispose();
    _dayStartMFocus.dispose(); _dayEndMFocus.dispose();
    _nightStartMFocus.dispose(); _nightEndMFocus.dispose();
    super.dispose();
  }

  bool get _hasChanges =>
      _name.text != _initName || _nickname.text != _initNickname ||
      _address.text != _initAddress || _email.text != _initEmail ||
      _phone.text != _initPhone || _hasNightShift != _initHasNightShift ||
      _dayStartH.text != _initDayStartH || _dayStartM.text != _initDayStartM ||
      _dayEndH.text != _initDayEndH || _dayEndM.text != _initDayEndM ||
      _nightStartH.text != _initNightStartH || _nightStartM.text != _initNightStartM ||
      _nightEndH.text != _initNightEndH || _nightEndM.text != _initNightEndM;

  bool _validateDayShift() {
    bool ok = true;
    void check(TextEditingController ctrl, GlobalKey<ShakeFieldState> key) {
      if (ctrl.text.trim().isEmpty) {
        key.currentState?.showError('');
        ok = false;
      } else {
        key.currentState?.clearError();
      }
    }
    check(_dayStartH, _dayStartHShake);
    check(_dayStartM, _dayStartMShake);
    check(_dayEndH, _dayEndHShake);
    check(_dayEndM, _dayEndMShake);
    return ok;
  }
  bool _validateTimeRanges() {
    bool ok = true;
    void checkRange(TextEditingController ctrl, GlobalKey<ShakeFieldState> key, int max) {
      final text = ctrl.text.trim();
      if (text.isEmpty) return;
      final n = int.tryParse(text);
      if (n == null || n > max) {
        key.currentState?.showError('');
        ok = false;
      }
    }
    checkRange(_dayStartH, _dayStartHShake, 23);
    checkRange(_dayStartM, _dayStartMShake, 59);
    checkRange(_dayEndH, _dayEndHShake, 23);
    checkRange(_dayEndM, _dayEndMShake, 59);
    if (_hasNightShift) {
      checkRange(_nightStartH, _nightStartHShake, 23);
      checkRange(_nightStartM, _nightStartMShake, 59);
      checkRange(_nightEndH, _nightEndHShake, 23);
      checkRange(_nightEndM, _nightEndMShake, 59);
    }
    return ok;
  }

  // 야간은 자정을 넘겨 종료될 수 있어 순서 검증 대상에서 제외
  bool _validateDayOrder() {
    final startMin = int.parse(_dayStartH.text) * 60 + int.parse(_dayStartM.text);
    final endMin = int.parse(_dayEndH.text) * 60 + int.parse(_dayEndM.text);
    if (endMin <= startMin) {
      _dayEndHShake.currentState?.showError('');
      _dayEndMShake.currentState?.showError('');
      return false;
    }
    return true;
  }

  bool _validateName() {
    if (_name.text.trim().isEmpty) {
      _nameShake.currentState?.showError('필수 항목입니다');
      return false;
    }
    _nameShake.currentState?.clearError();
    return true;
  }

  Future<void> _save() async {
    final nameOk = _validateName();
    final dayShiftOk = _validateDayShift();
    final rangeOk = _validateTimeRanges();
    final orderOk = (dayShiftOk && rangeOk) ? _validateDayOrder() : true;
    if (!nameOk || !dayShiftOk || !rangeOk || !orderOk) return;
    setState(() => _isSaving = true);
    try {
      final body = {
        'name': _name.text.trim(),
        'nickname': _nickname.text.trim(),
        'address': _address.text.trim(),
        'email': _email.text.trim(),
        'phone': _phone.text.trim(),
        'hasNightShift': _hasNightShift,
        'dayShiftStart': _timeValue(_dayStartH, _dayStartM),
        'dayShiftEnd': _timeValue(_dayEndH, _dayEndM),
        'nightShiftStart': _hasNightShift ? _timeValue(_nightStartH, _nightStartM) : null,
        'nightShiftEnd': _hasNightShift ? _timeValue(_nightEndH, _nightEndM) : null,
      };
      if (widget.item != null) {
        await widget.service.update(widget.item!.id, body);
      } else {
        await widget.service.create(body);
      }
      if (mounted) Navigator.pop(context);
      widget.onRefresh();
    } catch (e) {
      if (mounted) {
        setState(() => _isSaving = false);
        showToast(context, '저장 실패: $e');
      }
    }
  }

  Widget _textField(TextEditingController ctrl, String label, {bool required = false, GlobalKey<ShakeFieldState>? shakeKey}) {
    final decoration = InputDecoration(
      labelText: required ? '$label *' : label,
      labelStyle: TextStyle(color: Colors.grey[500]),
      floatingLabelStyle: const TextStyle(color: Colors.black87),
      enabledBorder: UnderlineInputBorder(borderSide: BorderSide(color: Colors.grey[300]!)),
      focusedBorder: const UnderlineInputBorder(borderSide: BorderSide(color: Colors.black87)),
    );
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: shakeKey != null
          ? ShakeField(
              key: shakeKey,
              controller: ctrl,
              decoration: decoration,
              onChanged: (v) {
                setState(() {});
                if (v.trim().isNotEmpty) shakeKey.currentState?.clearError();
              },
            )
          : TextField(
              controller: ctrl,
              onChanged: (_) => setState(() {}),
              decoration: decoration,
            ),
    );
  }

  Widget _digitBox(TextEditingController ctrl, {FocusNode? focusNode, FocusNode? nextFocus, GlobalKey<ShakeFieldState>? shakeKey}) {
    void onChanged(String v) {
      setState(() {});
      shakeKey?.currentState?.clearError();
      if (v.length == 2 && nextFocus != null) {
        FocusScope.of(context).requestFocus(nextFocus);
      }
    }

    final decoration = InputDecoration(
      counterText: '',
      hintText: '00',
      hintStyle: TextStyle(color: Colors.grey[400], fontSize: 14),
      contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 6),
      enabledBorder: OutlineInputBorder(
        borderSide: BorderSide(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      focusedBorder: OutlineInputBorder(
        borderSide: const BorderSide(color: Colors.blue),
        borderRadius: BorderRadius.circular(8),
      ),
    );

    return SizedBox(
      width: 44,
      child: shakeKey != null
          ? ShakeField(
              key: shakeKey,
              controller: ctrl,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              onChanged: onChanged,
              decoration: decoration,
            )
          : TextField(
              controller: ctrl,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              inputFormatters: [FilteringTextInputFormatter.digitsOnly, LengthLimitingTextInputFormatter(2)],
              onChanged: onChanged,
              decoration: decoration,
            ),
    );
  }

  Widget _timeField(
    String label,
    TextEditingController hCtrl,
    TextEditingController mCtrl,
    FocusNode mFocus, {
    IconData? icon,
    Color? iconColor,
    bool required = false,
    GlobalKey<ShakeFieldState>? hShakeKey,
    GlobalKey<ShakeFieldState>? mShakeKey,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Row(
        children: [
          if (icon != null) ...[
            Icon(icon, size: 16, color: iconColor),
            const SizedBox(width: 6),
          ],
          Expanded(child: Text(required ? '$label *' : label, style: TextStyle(fontSize: 14, color: Colors.grey[600]))),
          _digitBox(hCtrl, nextFocus: mFocus, shakeKey: hShakeKey),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 6),
            child: Text(':', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.grey[500])),
          ),
          _digitBox(mCtrl, focusNode: mFocus, shakeKey: mShakeKey),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FormDialog(
      title: widget.item != null ? '공장 수정' : '공장 추가',
      hasChanges: _hasChanges,
      isLoading: _isSaving,
      onSave: _save,
      content: ConstrainedBox(
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height * 0.6),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              _textField(_name, '이름', required: true, shakeKey: _nameShake),
              _textField(_nickname, '별칭'),
              _textField(_address, '주소'),
              _textField(_email, '이메일'),
              _textField(_phone, '전화번호'),
              SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('야간 시프트 여부', style: TextStyle(fontSize: 14)),
                value: _hasNightShift,
                onChanged: (v) => setState(() => _hasNightShift = v),
              ),
              _timeField(
                '주간 시작', _dayStartH, _dayStartM, _dayStartMFocus,
                icon: Icons.wb_sunny, iconColor: Colors.orange,
                required: true, hShakeKey: _dayStartHShake, mShakeKey: _dayStartMShake,
              ),
              _timeField(
                '주간 종료', _dayEndH, _dayEndM, _dayEndMFocus,
                icon: Icons.wb_sunny, iconColor: Colors.orange,
                required: true, hShakeKey: _dayEndHShake, mShakeKey: _dayEndMShake,
              ),
              if (_hasNightShift) ...[
                _timeField(
                  '야간 시작', _nightStartH, _nightStartM, _nightStartMFocus,
                  icon: Icons.nightlight_round, iconColor: Colors.deepPurple,
                  hShakeKey: _nightStartHShake, mShakeKey: _nightStartMShake,
                ),
                _timeField(
                  '야간 종료', _nightEndH, _nightEndM, _nightEndMFocus,
                  icon: Icons.nightlight_round, iconColor: Colors.deepPurple,
                  hShakeKey: _nightEndHShake, mShakeKey: _nightEndMShake,
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}