import 'package:dpr_frontend/features/settings/models/factory_shift.dart';

int _toMinutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

bool isEditAllowed(FactoryShift? shift, String selectedDate) {
  final now = DateTime.now();
  final todayStr = now.toIso8601String().substring(0, 10);
  if (selectedDate != todayStr) return false;

  if (shift == null) return true;

  final nowMinutes = now.hour * 60 + now.minute;

  // 야간 시프트 없음
  if (!shift.hasNightShift) {
    // 주간 시간 범위 확인
    final start = _toMinutes(shift.dayShiftStart);
    final end = _toMinutes(shift.dayShiftEnd);
    return nowMinutes >= start && nowMinutes <= end;
  }

  // 야간 시프트 있음
  final start = _toMinutes(shift.dayShiftStart);
  final end = _toMinutes(shift.nightShiftEnd!);
  if (end >= start) {
    return nowMinutes >= start && nowMinutes <= end;
  } else {
    return nowMinutes >= start || nowMinutes <= end; // 자정 넘김
  }
}