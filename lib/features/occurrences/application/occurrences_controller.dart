import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/storage/persisted_json.dart';
import '../../../core/storage/preferences_provider.dart';
import '../../settings/application/settings_controller.dart';
import '../domain/occurrence.dart';

/// Relatos do cidadão, guardados só no aparelho (funciona sem conexão).
class OccurrencesController extends Notifier<List<Occurrence>> {
  static const _key = 'occurrences.items';

  SharedPreferences get _prefs => ref.read(sharedPreferencesProvider);

  @override
  List<Occurrence> build() {
    // Recarrega quando o consentimento muda (retirar apaga os dados).
    ref.watch(settingsProvider.select((s) => s.consentGiven));
    final raw = PersistedJson.read(ref.read(sharedPreferencesProvider), _key);
    if (raw is! List) return const [];
    final items = <Occurrence>[];
    for (final item in raw) {
      try {
        items.add(Occurrence.fromJson(item as Map<String, dynamic>));
      } on Object {
        // Ignora registros corrompidos em vez de derrubar a tela.
      }
    }
    return items;
  }

  Future<void> add(Occurrence occurrence) async {
    state = [occurrence, ...state];
    await _save();
  }

  Future<void> remove(String id) async {
    state = state.where((o) => o.id != id).toList();
    await _save();
  }

  Future<void> _save() =>
      PersistedJson.write(_prefs, _key, state.map((o) => o.toJson()).toList());
}

final occurrencesProvider =
    NotifierProvider<OccurrencesController, List<Occurrence>>(
      OccurrencesController.new,
    );
