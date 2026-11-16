import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mirante/app.dart';
import 'package:mirante/core/providers.dart';
import 'package:mirante/core/storage/preferences_provider.dart';
import 'package:mirante/features/climate/application/climate_providers.dart';
import 'package:mirante/features/climate/data/climate_repository.dart';
import 'package:mirante/features/climate/domain/climate_snapshot.dart';
import 'package:mirante/features/territory_data/application/territory_data_providers.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'fixtures.dart';

/// Repositório de clima falso: devolve o fixture ou simula falta de conexão.
class FakeClimateRepository implements ClimateRepository {
  FakeClimateRepository({this.snapshot, this.offline = false});

  final ClimateSnapshot? snapshot;
  final bool offline;

  @override
  Future<ClimateSnapshot> load() async {
    if (offline) {
      throw const ClimateUnavailableException('sem conexão (teste)');
    }
    return snapshot ?? climateFixture();
  }
}

/// Sobe o app com dados de teste: sem rede, sem atraso e com data fixa.
Future<void> pumpMirante(
  WidgetTester tester, {
  bool consent = true,
  bool offline = false,
  ClimateSnapshot? climate,
  Size size = const Size(412, 915),
}) async {
  await initializeDateFormatting('pt_BR');
  tester.view
    ..physicalSize = size * 2.625
    ..devicePixelRatio = 2.625;
  addTearDown(tester.view.reset);

  SharedPreferences.setMockInitialValues({
    if (consent) 'settings.consent_given': true,
  });
  final prefs = await SharedPreferences.getInstance();

  await tester.pumpWidget(
    ProviderScope(
      retry: (_, _) => null,
      overrides: [
        sharedPreferencesProvider.overrideWithValue(prefs),
        clockProvider.overrideWithValue(
          () => today.add(const Duration(hours: 9)),
        ),
        syntheticLatencyProvider.overrideWithValue(Duration.zero),
        climateRepositoryProvider.overrideWithValue(
          FakeClimateRepository(snapshot: climate, offline: offline),
        ),
      ],
      child: const MiranteApp(),
    ),
  );
  await tester.pumpAndSettle();
}

/// Rola a tela visível até o widget aparecer. Arrasta pela margem esquerda,
/// que pertence à lista da página (e não a gráficos ou campos de texto).
Future<void> scrollTo(WidgetTester tester, Finder finder) async {
  final size = tester.view.physicalSize / tester.view.devicePixelRatio;
  for (var i = 0; i < 40 && finder.evaluate().isEmpty; i++) {
    await tester.dragFrom(Offset(6, size.height * 0.6), const Offset(0, -250));
    await tester.pumpAndSettle();
  }
  await tester.ensureVisible(finder.first);
  await tester.pumpAndSettle();
}
