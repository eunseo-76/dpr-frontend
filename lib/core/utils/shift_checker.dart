import 'package:flutter/foundation.dart';
import 'package:dpr_frontend/features/settings/models/factory_shift.dart';

int _toMinutes(String time) {
  final parts = time.split(':');
  return int.parse(parts[0]) * 60 + int.parse(parts[1]);
}

DateTime _timeOnDate(DateTime date, String time) {
  final parts = time.split(':');
  return DateTime(
    date.year,
    date.month,
    date.day,
    int.parse(parts[0]),
    int.parse(parts[1]),
  );
}

// 백엔드 Factory.isWithinModifiableWindow()와 동일한 공식.
// windowEnd = (주간만 있으면 주간 퇴근, 야간반 있으면 야간 퇴근 — 자정 넘기면 다음날) + 24시간
bool isEditAllowed(FactoryShift? shift, String selectedDate) {
  if (shift == null) {
    // 시프트 정보가 없으면 공식 자체를 적용할 수 없음 — 기존처럼 오늘 날짜만 허용
    final todayStr = DateTime.now().toIso8601String().substring(0, 10);
    return selectedDate == todayStr;
  }

  final date = DateTime.parse(selectedDate);
  final windowStart = _timeOnDate(date, shift.dayShiftStart);

  final DateTime windowEndBase;
  if (!shift.hasNightShift) {
    windowEndBase = _timeOnDate(date, shift.dayShiftEnd);
  } else {
    // 자정 넘김 여부는 야간 시작 vs 야간 종료로 판단 (주간 시작과는 무관).
    final crossesMidnight =
        _toMinutes(shift.nightShiftEnd!) < _toMinutes(shift.nightShiftStart!);
    final endDate = crossesMidnight ? date.add(const Duration(days: 1)) : date;
    windowEndBase = _timeOnDate(endDate, shift.nightShiftEnd!);
  }
  final windowEnd = windowEndBase.add(const Duration(hours: 24));

  final now = DateTime.now();
  final result = now.isAfter(windowStart) && now.isBefore(windowEnd);
  debugPrint(
    '[isEditAllowed] selectedDate=$selectedDate hasNightShift=${shift.hasNightShift} '
    'dayShiftStart=${shift.dayShiftStart} dayShiftEnd=${shift.dayShiftEnd} '
    'nightShiftStart=${shift.nightShiftStart} nightShiftEnd=${shift.nightShiftEnd} '
    'windowStart=$windowStart windowEnd=$windowEnd now=$now result=$result',
  );
  return result;
}