import 'package:intl/intl.dart';

String formatNumber(double value) {
  return NumberFormat('#,##0.###').format(value);
}

String formatCompact(double value) {
  final abs = value.abs();
  if (abs >= 100000000) {
    return '${NumberFormat('#,##0.#').format(value / 100000000)}억';
  } else if (abs >= 10000) {
    return '${NumberFormat('#,##0.#').format(value / 10000)}만';
  }
  return formatNumber(value);
}