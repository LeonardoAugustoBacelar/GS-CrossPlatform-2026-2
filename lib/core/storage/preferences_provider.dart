import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// Instância de SharedPreferences carregada em `main.dart`, antes do app subir.
/// Assim as telas leem preferências de forma síncrona.
final sharedPreferencesProvider = Provider<SharedPreferences>(
  (ref) =>
      throw UnimplementedError('Sobrescrito no ProviderScope de main.dart'),
);
