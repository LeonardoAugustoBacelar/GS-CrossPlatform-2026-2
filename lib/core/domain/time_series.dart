/// Ponto observado de uma série diária.
class DataPoint {
  const DataPoint(this.date, this.value);

  final DateTime date;
  final double value;
}

/// Ponto previsto, com intervalo de incerteza opcional.
class ForecastPoint {
  const ForecastPoint({
    required this.date,
    required this.value,
    double? lower,
    double? upper,
  }) : lower = lower ?? value,
       upper = upper ?? value;

  final DateTime date;
  final double value;
  final double lower;
  final double upper;

  bool get hasInterval => upper > lower;
}

DateTime dateOnly(DateTime date) => DateTime(date.year, date.month, date.day);

DateTime addDays(DateTime date, int days) =>
    DateTime(date.year, date.month, date.day + days);

/// Chave `aaaa-mm-dd`, no mesmo formato das APIs.
String dateKey(DateTime date) {
  String two(int value) => value.toString().padLeft(2, '0');
  return '${date.year}-${two(date.month)}-${two(date.day)}';
}

DateTime parseDateKey(String key) {
  final parts = key.substring(0, 10).split('-').map(int.parse).toList();
  return DateTime(parts[0], parts[1], parts[2]);
}

/// Dias inteiros de [from] até [to] (positivo se [to] for depois).
int daysBetween(DateTime from, DateTime to) =>
    (dateOnly(to).difference(dateOnly(from)).inHours / 24).round();

bool isWeekend(DateTime date) =>
    date.weekday == DateTime.saturday || date.weekday == DateTime.sunday;
