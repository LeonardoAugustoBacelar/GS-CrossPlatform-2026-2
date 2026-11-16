import 'dart:convert';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'preferences_provider.dart';

/// Cache de respostas JSON no aparelho, para o app funcionar sem conexão.
class JsonCache {
  JsonCache(this._prefs);

  final SharedPreferences _prefs;

  Map<String, dynamic>? read(String key) {
    final raw = _prefs.getString('cache.$key');
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } on FormatException {
      return null;
    }
  }

  Future<void> write(String key, Map<String, dynamic> value) =>
      _prefs.setString('cache.$key', jsonEncode(value));
}

final jsonCacheProvider = Provider<JsonCache>(
  (ref) => JsonCache(ref.watch(sharedPreferencesProvider)),
);
