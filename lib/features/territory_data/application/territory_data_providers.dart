import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/time_series.dart';
import '../../../core/providers.dart';
import '../../climate/application/climate_providers.dart';
import '../../climate/domain/climate_snapshot.dart';
import '../data/synthetic_territory_api.dart';
import '../domain/territory_dataset.dart';

/// Latência simulada da API. Os testes zeram este valor.
final syntheticLatencyProvider = Provider<Duration>(
  (ref) => const Duration(milliseconds: 600),
);

/// Dados sintéticos de recursos e serviços. Não depende de conexão: se o
/// clima real falhar, a API simulada usa uma climatologia como fator.
final territoryDatasetProvider = FutureProvider<TerritoryDataset>((ref) async {
  ClimateSnapshot? climate;
  try {
    climate = await ref.watch(climateProvider.future);
  } on Object {
    climate = null;
  }
  final api = SyntheticTerritoryApi(
    today: ref.watch(clockProvider)(),
    latency: ref.watch(syntheticLatencyProvider),
    realTempMax: {
      for (final day in climate?.days ?? const <DailyWeather>[])
        dateKey(day.date): day.tempMax,
    },
  );
  return TerritoryDataset.fromJson(await api.fetchDailySeries());
});
