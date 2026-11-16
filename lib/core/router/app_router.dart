import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/presentation/alert_detail_screen.dart';
import '../../features/alerts/presentation/alerts_screen.dart';
import '../../features/consent/presentation/consent_screen.dart';
import '../../features/dashboards/presentation/dashboard_screen.dart';
import '../../features/indicators/presentation/indicator_detail_screen.dart';
import '../../features/occurrences/presentation/occurrence_form_screen.dart';
import '../../features/overview/presentation/overview_screen.dart';
import '../../features/settings/application/settings_controller.dart';
import '../../features/settings/presentation/settings_screen.dart';
import '../../shared/widgets/state_views.dart';
import '../domain/territory_area.dart';
import 'app_routes.dart';
import 'app_shell.dart';

/// Mapa de navegação:
///
/// ```text
/// /consentimento                          (antes de tudo, se não houver consentimento)
/// /                                       visão geral          ┐
/// /painel/:area                           dashboard da área    │ aba Início
/// /painel/:area/indicador/:indicatorId    detalhe do indicador ┘
/// /alertas                                lista de alertas     ┐ aba Alertas
/// /alertas/:alertId                       detalhe do alerta    ┘
/// /relatar                                formulário de ocorrência (aba Relatar)
/// /ajustes                                acessibilidade e privacidade (aba Ajustes)
/// ```
final routerProvider = Provider<GoRouter>((ref) {
  final consentGiven = ValueNotifier<bool>(
    ref.read(settingsProvider).consentGiven,
  );
  ref.listen<bool>(
    settingsProvider.select((settings) => settings.consentGiven),
    (_, next) => consentGiven.value = next,
  );
  ref.onDispose(consentGiven.dispose);

  return GoRouter(
    initialLocation: '/',
    refreshListenable: consentGiven,
    redirect: (context, state) {
      final atConsent = state.matchedLocation == '/consentimento';
      if (!consentGiven.value) return atConsent ? null : '/consentimento';
      return atConsent ? '/' : null;
    },
    errorBuilder: (context, state) => const _NotFoundScreen(),
    routes: [
      GoRoute(
        path: '/consentimento',
        name: AppRoutes.consent,
        builder: (context, state) => const ConsentScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, shell) => AppShell(navigationShell: shell),
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                name: AppRoutes.overview,
                builder: (context, state) => const OverviewScreen(),
                routes: [
                  GoRoute(
                    path: 'painel/:area',
                    name: AppRoutes.dashboard,
                    builder: (context, state) {
                      final area = TerritoryArea.fromPath(
                        state.pathParameters['area'],
                      );
                      if (area == null) return const _NotFoundScreen();
                      return DashboardScreen(area: area);
                    },
                    routes: [
                      GoRoute(
                        path: 'indicador/:indicatorId',
                        name: AppRoutes.indicatorDetail,
                        builder: (context, state) => IndicatorDetailScreen(
                          indicatorId: state.pathParameters['indicatorId']!,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alertas',
                name: AppRoutes.alerts,
                builder: (context, state) => const AlertsScreen(),
                routes: [
                  GoRoute(
                    path: ':alertId',
                    name: AppRoutes.alertDetail,
                    builder: (context, state) => AlertDetailScreen(
                      alertId: state.pathParameters['alertId']!,
                    ),
                  ),
                ],
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/relatar',
                name: AppRoutes.report,
                builder: (context, state) => const OccurrenceFormScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/ajustes',
                name: AppRoutes.settings,
                builder: (context, state) => const SettingsScreen(),
              ),
            ],
          ),
        ],
      ),
    ],
  );
});

class _NotFoundScreen extends StatelessWidget {
  const _NotFoundScreen();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Página não encontrada')),
      body: EmptyView(
        icon: Icons.explore_off_outlined,
        message: 'Este conteúdo não existe ou foi removido.',
        action: FilledButton(
          onPressed: () => context.goNamed(AppRoutes.overview),
          child: const Text('Voltar ao início'),
        ),
      ),
    );
  }
}
