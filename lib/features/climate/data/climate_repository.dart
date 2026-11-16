import '../../../core/domain/time_series.dart';
import '../../../core/storage/json_cache.dart';
import '../domain/climate_snapshot.dart';
import 'open_meteo_client.dart';

/// Busca o clima na API e guarda a última resposta boa no aparelho.
/// Sem conexão, devolve a cópia salva (marcada como `fromCache`).
class ClimateRepository {
  ClimateRepository({
    required this._client,
    required this._cache,
    required this._clock,
  });

  final OpenMeteoClient _client;
  final JsonCache _cache;
  final DateTime Function() _clock;

  static const _cacheKey = 'climate';

  Future<ClimateSnapshot> load() async {
    try {
      final weather = await _client.fetchWeather();
      Map<String, dynamic>? air;
      try {
        air = await _client.fetchAirQuality();
      } on Exception {
        // Qualidade do ar é complementar: o painel segue sem ela.
        air = _cache.read(_cacheKey)?['air'] as Map<String, dynamic>?;
      }
      final payload = {
        'fetchedAt': _clock().toIso8601String(),
        'weather': weather,
        'air': air,
      };
      await _cache.write(_cacheKey, payload);
      return parse(payload, fromCache: false);
    } on Exception catch (error) {
      final cached = _cache.read(_cacheKey);
      if (cached == null) throw ClimateUnavailableException(error);
      return parse(cached, fromCache: true);
    }
  }

  /// Converte a resposta da Open-Meteo. Público para os testes.
  static ClimateSnapshot parse(
    Map<String, dynamic> payload, {
    required bool fromCache,
  }) {
    final daily =
        (payload['weather'] as Map<String, dynamic>)['daily']
            as Map<String, dynamic>;
    final times = (daily['time'] as List).cast<String>();
    final pm25ByDay = _dailyMeans(payload['air'] as Map<String, dynamic>?);

    double? at(String field, int i) =>
        ((daily[field] as List?)?[i] as num?)?.toDouble();

    final days = <DailyWeather>[];
    for (var i = 0; i < times.length; i++) {
      final tempMax = at('temperature_2m_max', i);
      final tempMin = at('temperature_2m_min', i);
      if (tempMax == null || tempMin == null) continue;
      days.add(
        DailyWeather(
          date: parseDateKey(times[i]),
          tempMax: tempMax,
          tempMin: tempMin,
          precipitation: at('precipitation_sum', i) ?? 0,
          precipitationProbability: at('precipitation_probability_max', i),
          pm25: pm25ByDay[times[i]],
        ),
      );
    }

    return ClimateSnapshot(
      days: days,
      fetchedAt: DateTime.parse(payload['fetchedAt'] as String),
      fromCache: fromCache,
    );
  }

  /// Média diária das medições horárias (exige ao menos 12 horas no dia).
  static Map<String, double> _dailyMeans(Map<String, dynamic>? air) {
    if (air == null) return const {};
    final hourly = air['hourly'] as Map<String, dynamic>;
    final times = (hourly['time'] as List).cast<String>();
    final values = hourly['pm2_5'] as List;
    final sums = <String, double>{};
    final counts = <String, int>{};
    for (var i = 0; i < times.length; i++) {
      final value = (values[i] as num?)?.toDouble();
      if (value == null) continue;
      final day = times[i].substring(0, 10);
      sums[day] = (sums[day] ?? 0) + value;
      counts[day] = (counts[day] ?? 0) + 1;
    }
    return {
      for (final day in sums.keys)
        if (counts[day]! >= 12) day: sums[day]! / counts[day]!,
    };
  }
}
