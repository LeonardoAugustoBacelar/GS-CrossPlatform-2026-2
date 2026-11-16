import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../features/alerts/application/alerts_providers.dart';
import '../features/climate/application/climate_providers.dart';
import '../features/territory_data/application/territory_data_providers.dart';

/// Busca de novo os dados do território (puxar para atualizar / tentar de novo).
Future<void> refreshTerritoryData(WidgetRef ref) async {
  ref
    ..invalidate(climateProvider)
    ..invalidate(territoryDatasetProvider);
  try {
    await ref.read(alertReportProvider.future);
  } on Object {
    // O estado de erro já é exibido pela própria tela.
  }
}
