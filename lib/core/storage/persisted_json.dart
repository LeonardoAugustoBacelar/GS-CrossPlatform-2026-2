import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

/// Lê e grava JSON simples no SharedPreferences, tolerando dados corrompidos.
abstract final class PersistedJson {
  static Object? read(SharedPreferences prefs, String key) {
    final raw = prefs.getString(key);
    if (raw == null) return null;
    try {
      return jsonDecode(raw);
    } on FormatException {
      return null;
    }
  }

  static Future<void> write(
    SharedPreferences prefs,
    String key,
    Object value,
  ) => prefs.setString(key, jsonEncode(value));
}
