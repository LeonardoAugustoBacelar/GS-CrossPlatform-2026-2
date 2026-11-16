/// Um dia de clima: observado (passado) ou previsto (hoje em diante).
class DailyWeather {
  const DailyWeather({
    required this.date,
    required this.tempMax,
    required this.tempMin,
    required this.precipitation,
    this.precipitationProbability,
    this.pm25,
  });

  final DateTime date;
  final double tempMax;
  final double tempMin;

  /// Chuva acumulada no dia, em mm.
  final double precipitation;

  /// Probabilidade máxima de chuva no dia (0 a 100), só na previsão.
  final double? precipitationProbability;

  /// Média diária de partículas finas (µg/m³).
  final double? pm25;
}

/// Resultado de uma consulta de clima, da API ou do cache local.
class ClimateSnapshot {
  const ClimateSnapshot({
    required this.days,
    required this.fetchedAt,
    required this.fromCache,
  });

  final List<DailyWeather> days;
  final DateTime fetchedAt;
  final bool fromCache;

  bool get hasAirQuality => days.any((day) => day.pm25 != null);
}

class ClimateUnavailableException implements Exception {
  const ClimateUnavailableException(this.cause);

  final Object cause;

  @override
  String toString() => 'Clima indisponível e sem cache: $cause';
}
