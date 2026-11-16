import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/indicator.dart';
import '../../../core/domain/territory_area.dart';
import '../../../core/providers.dart';
import '../../climate/application/climate_providers.dart';
import '../../territory_data/application/territory_data_providers.dart';
import '../domain/indicator_builder.dart';

/// Indicadores de uma área. Cada área depende só da sua fonte: se o clima
/// falhar, os painéis de recursos e serviços continuam funcionando.
final areaIndicatorsProvider =
    FutureProvider.family<List<Indicator>, TerritoryArea>((ref, area) async {
      final today = ref.watch(clockProvider)();
      switch (area) {
        case TerritoryArea.clima:
          final climate = await ref.watch(climateProvider.future);
          return IndicatorBuilder.climate(climate, today);
        case TerritoryArea.recursos:
          final data = await ref.watch(territoryDatasetProvider.future);
          return IndicatorBuilder.resources(data, today);
        case TerritoryArea.servicos:
          final data = await ref.watch(territoryDatasetProvider.future);
          return IndicatorBuilder.services(data, today);
      }
    });

/// Todos os indicadores disponíveis, por id (áreas indisponíveis ficam de fora).
final availableIndicatorsProvider = FutureProvider<Map<String, Indicator>>((
  ref,
) async {
  final result = <String, Indicator>{};
  for (final area in TerritoryArea.values) {
    try {
      for (final indicator in await ref.watch(
        areaIndicatorsProvider(area).future,
      )) {
        result[indicator.id] = indicator;
      }
    } on Object {
      // Área sem dados: as telas dela mostram o próprio estado de erro.
    }
  }
  return result;
});

final indicatorProvider = FutureProvider.family<Indicator?, String>((
  ref,
  id,
) async {
  final all = await ref.watch(availableIndicatorsProvider.future);
  return all[id];
});
