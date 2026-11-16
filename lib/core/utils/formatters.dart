import 'package:intl/intl.dart';

import '../domain/time_series.dart';

/// Formatação em pt-BR. `initializeDateFormatting('pt_BR')` roda em main.dart.
abstract final class Fmt {
  static String number(num value, {int decimals = 0}) {
    final pattern = decimals == 0 ? '#,##0' : '#,##0.${'0' * decimals}';
    return NumberFormat(pattern, 'pt_BR').format(value);
  }

  /// Ex.: 0,084 → "8,4%".
  static String percent(double ratio, {int decimals = 0}) =>
      '${number(ratio * 100, decimals: decimals)}%';

  /// Ex.: 570000 → "570 mil".
  static String compact(num value) {
    if (value >= 1000000) return '${number(value / 1000000, decimals: 1)} mi';
    if (value >= 1000) return '${number(value / 1000)} mil';
    return number(value);
  }

  static String day(DateTime date) => DateFormat('dd/MM', 'pt_BR').format(date);

  static String weekdayDay(DateTime date) =>
      DateFormat('EEEE (dd/MM)', 'pt_BR').format(date);

  static String shortWeekday(DateTime date) =>
      DateFormat('EEE', 'pt_BR').format(date).replaceAll('.', '');

  static String dateTime(DateTime date) =>
      DateFormat("dd/MM 'às' HH:mm", 'pt_BR').format(date);

  /// Ex.: "hoje", "amanhã", "em 3 dias", "há 2 dias".
  static String relativeDay(DateTime target, DateTime today) {
    final diff = daysBetween(today, target);
    return switch (diff) {
      0 => 'hoje',
      1 => 'amanhã',
      -1 => 'ontem',
      > 1 => 'em $diff dias',
      _ => 'há ${-diff} dias',
    };
  }
}
