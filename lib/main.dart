import 'package:flutter/widgets.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'app.dart';
import 'core/storage/preferences_provider.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR');
  final preferences = await SharedPreferences.getInstance();

  runApp(
    ProviderScope(
      // Sem novas tentativas automáticas: erros aparecem na tela com o botão
      // "Tentar de novo", e o app usa o cache quando está offline.
      retry: (_, _) => null,
      overrides: [sharedPreferencesProvider.overrideWithValue(preferences)],
      child: const MiranteApp(),
    ),
  );
}
