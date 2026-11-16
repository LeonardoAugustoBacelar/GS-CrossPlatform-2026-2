import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/providers.dart';
import '../../../core/storage/persisted_json.dart';
import '../../../core/storage/preferences_provider.dart';
import '../../climate/application/climate_providers.dart';
import '../../climate/domain/climate_snapshot.dart';
import '../../indicators/application/indicators_providers.dart';
import '../../occurrences/application/occurrences_controller.dart';
import '../../settings/application/settings_controller.dart';
import '../../territory_data/application/territory_data_providers.dart';
import '../../territory_data/domain/territory_dataset.dart';
import '../domain/alert_decision.dart';
import '../domain/alert_engine.dart';
import '../domain/alert_thresholds.dart';
import '../domain/territory_alert.dart';

/// Limiares configurados pelo gestor, persistidos no aparelho.
class ThresholdsController extends Notifier<AlertThresholds> {
  static const _key = 'alerts.thresholds';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  AlertThresholds build() {
    ref.watch(settingsProvider.select((s) => s.consentGiven));
    final raw = PersistedJson.read(ref.read(sharedPreferencesProvider), _key);
    return raw is Map<String, dynamic>
        ? AlertThresholds.fromJson(raw)
        : const AlertThresholds();
  }

  Future<void> save(AlertThresholds thresholds) async {
    state = thresholds;
    await PersistedJson.write(_prefs, _key, thresholds.toJson());
  }

  Future<void> reset() => save(const AlertThresholds());
}

final thresholdsProvider =
    NotifierProvider<ThresholdsController, AlertThresholds>(
      ThresholdsController.new,
    );

/// Decisões humanas registradas sobre os alertas (id do alerta → decisão).
class DecisionsController extends Notifier<Map<String, AlertDecision>> {
  static const _key = 'alerts.decisions';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  Map<String, AlertDecision> build() {
    ref.watch(settingsProvider.select((s) => s.consentGiven));
    final raw = PersistedJson.read(ref.read(sharedPreferencesProvider), _key);
    if (raw is! Map<String, dynamic>) return const {};
    final decisions = <String, AlertDecision>{};
    for (final entry in raw.entries) {
      try {
        decisions[entry.key] = AlertDecision.fromJson(
          entry.value as Map<String, dynamic>,
        );
      } on Object {
        // Registro corrompido: ignorado.
      }
    }
    return decisions;
  }

  Future<void> record(AlertDecision decision) async {
    state = {...state, decision.alertId: decision};
    await _save();
  }

  Future<void> clear(String alertId) async {
    state = {...state}..remove(alertId);
    await _save();
  }

  Future<void> _save() => PersistedJson.write(_prefs, _key, {
    for (final entry in state.entries) entry.key: entry.value.toJson(),
  });
}

final decisionsProvider =
    NotifierProvider<DecisionsController, Map<String, AlertDecision>>(
      DecisionsController.new,
    );

/// Relatório de alertas: avalia tudo o que estiver disponível.
final alertReportProvider = FutureProvider<AlertReport>((ref) async {
  ClimateSnapshot? climate;
  try {
    climate = await ref.watch(climateProvider.future);
  } on Object {
    climate = null;
  }
  TerritoryDataset? dataset;
  try {
    dataset = await ref.watch(territoryDatasetProvider.future);
  } on Object {
    dataset = null;
  }

  return AlertEngine.evaluate(
    AlertInputs(
      today: ref.watch(clockProvider)(),
      thresholds: ref.watch(thresholdsProvider),
      climate: climate,
      dataset: dataset,
      indicators: await ref.watch(availableIndicatorsProvider.future),
      occurrences: ref.watch(occurrencesProvider),
    ),
  );
});

final alertProvider = FutureProvider.family<TerritoryAlert?, String>((
  ref,
  id,
) async {
  final report = await ref.watch(alertReportProvider.future);
  for (final alert in report.alerts) {
    if (alert.id == id) return alert;
  }
  return null;
});
