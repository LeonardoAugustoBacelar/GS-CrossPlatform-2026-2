import 'package:mirante/core/domain/time_series.dart';
import 'package:mirante/features/climate/domain/climate_snapshot.dart';
import 'package:mirante/features/territory_data/data/synthetic_territory_api.dart';
import 'package:mirante/features/territory_data/domain/territory_dataset.dart';

/// Data fixa usada em todos os testes.
final today = DateTime(2026, 11, 16);

/// Clima de teste: 30 dias de histórico ameno + 7 dias de previsão.
ClimateSnapshot climateFixture({
  List<double> forecastMax = const [27, 28, 27, 26, 27, 28, 27],
  List<double> forecastRain = const [0, 2, 0, 1, 0, 0, 3],
  List<double>? forecastPm25,
  double rainProbability = 80,
  bool fromCache = false,
}) {
  final days = <DailyWeather>[
    for (var i = 30; i >= 1; i--)
      DailyWeather(
        date: addDays(today, -i),
        tempMax: 26 + (i % 3),
        tempMin: 17,
        precipitation: i % 5 == 0 ? 4 : 0,
        pm25: 12,
      ),
    for (var i = 0; i < forecastMax.length; i++)
      DailyWeather(
        date: addDays(today, i),
        tempMax: forecastMax[i],
        tempMin: 18,
        precipitation: forecastRain[i],
        precipitationProbability: rainProbability,
        pm25: forecastPm25 == null || i >= forecastPm25.length
            ? 12
            : forecastPm25[i],
      ),
  ];
  return ClimateSnapshot(
    days: days,
    fetchedAt: today.add(const Duration(hours: 8)),
    fromCache: fromCache,
  );
}

TerritoryDataset datasetFixture({ClimateSnapshot? climate}) {
  final api = SyntheticTerritoryApi(
    today: today,
    latency: Duration.zero,
    realTempMax: {
      for (final day in climate?.days ?? const <DailyWeather>[])
        dateKey(day.date): day.tempMax,
    },
  );
  return TerritoryDataset.fromJson(api.generate());
}
