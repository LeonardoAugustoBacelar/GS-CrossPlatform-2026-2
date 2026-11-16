import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/application/alerts_providers.dart';
import '../../features/alerts/domain/alert_engine.dart';
import '../../features/alerts/domain/territory_alert.dart';
import '../../features/notifications/alert_notifier.dart';
import 'app_routes.dart';

/// Estrutura com barra de navegação inferior, compartilhada pelas quatro abas.
/// Também dispara as notificações de alertas críticos (se ativadas).
class AppShell extends ConsumerWidget {
  const AppShell({super.key, required this.navigationShell});

  final StatefulNavigationShell navigationShell;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    ref.listen<AsyncValue<AlertReport>>(alertReportProvider, (_, next) {
      final report = next.value;
      if (report == null) return;
      final notifier = ref.read(alertNotifierProvider)
        ..onOpenAlert = (id) => context.goNamed(
          AppRoutes.alertDetail,
          pathParameters: {'alertId': id},
        );
      notifier.notifyCritical(report.alerts);
    });

    final critical =
        ref
            .watch(alertReportProvider)
            .value
            ?.alerts
            .where((a) => a.severity == AlertSeverity.high)
            .length ??
        0;

    return Scaffold(
      body: navigationShell,
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: (index) => navigationShell.goBranch(
          index,
          // Tocar na aba já aberta volta para a tela inicial dela.
          initialLocation: index == navigationShell.currentIndex,
        ),
        destinations: [
          const NavigationDestination(
            icon: Icon(Icons.dashboard_outlined),
            selectedIcon: Icon(Icons.dashboard),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Badge(
              isLabelVisible: critical > 0,
              label: Text('$critical'),
              child: const Icon(Icons.notifications_outlined),
            ),
            selectedIcon: Badge(
              isLabelVisible: critical > 0,
              label: Text('$critical'),
              child: const Icon(Icons.notifications),
            ),
            label: 'Alertas',
            tooltip: critical > 0 ? 'Alertas, $critical críticos' : 'Alertas',
          ),
          const NavigationDestination(
            icon: Icon(Icons.edit_note_outlined),
            selectedIcon: Icon(Icons.edit_note),
            label: 'Relatar',
          ),
          const NavigationDestination(
            icon: Icon(Icons.settings_outlined),
            selectedIcon: Icon(Icons.settings),
            label: 'Ajustes',
          ),
        ],
      ),
    );
  }
}
