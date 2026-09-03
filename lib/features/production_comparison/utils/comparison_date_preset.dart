// 대상 달에 A와 같은 일(day)이 없으면 그 달의 마지막 날로 clamp (예: 2/29 전년비교)
DateTime computePresetDateB({required DateTime dateA, required String preset}) {
  assert(preset == 'year' || preset == 'month', "preset은 'year' 또는 'month'만 가능: $preset");

  final monthsBack = preset == 'year' ? 12 : 1;
  final totalMonths = dateA.year * 12 + (dateA.month - 1) - monthsBack;
  final targetYear = totalMonths ~/ 12;
  final targetMonth = totalMonths % 12 + 1;

  final lastDayOfTargetMonth = DateTime(targetYear, targetMonth + 1, 0).day;
  final targetDay = dateA.day > lastDayOfTargetMonth ? lastDayOfTargetMonth : dateA.day;

  return DateTime(targetYear, targetMonth, targetDay);
}
