import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/providers.dart';
import '../../../core/storage/json_cache.dart';
import '../data/climate_repository.dart';
import '../data/open_meteo_client.dart';
import '../domain/climate_snapshot.dart';

final climateRepositoryProvider = Provider<ClimateRepository>(
  (ref) => ClimateRepository(
    client: OpenMeteoClient(ref.watch(httpClientProvider)),
    cache: ref.watch(jsonCacheProvider),
    clock: ref.watch(clockProvider),
  ),
);

/// Clima real do território (histórico + previsão), com cache offline.
final climateProvider = FutureProvider<ClimateSnapshot>(
  (ref) => ref.watch(climateRepositoryProvider).load(),
);
