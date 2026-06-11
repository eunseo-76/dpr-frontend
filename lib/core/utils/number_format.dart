import 'package:intl/intl.dart';
// 정수 -> ,
// 소수 -> 소수점 세 번째자리까지
String formatNumber(double value) {
  // TODO: 소수점 몇 번째 자리까지 표시할 지 결정
  return NumberFormat('#,##0.###').format(value);
}