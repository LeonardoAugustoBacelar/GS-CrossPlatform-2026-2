import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/territory_area.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/refresh.dart';
import '../../../shared/widgets/human_decision_banner.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/alerts_providers.dart';
import 'widgets/alert_widgets.dart';

/// Lista de alertas. O filtro por área é estado **local** desta tela; os
/// alertas e as decisões são estado **global** (compartilhado com outras telas).
class AlertsScreen extends ConsumerStatefulWidget {
  const AlertsScreen({super.key});

  @override
  ConsumerState<AlertsScreen> createState() => _AlertsScreenState();
}

class _AlertsScreenState extends ConsumerState<AlertsScreen> {
  TerritoryArea? _filter;

  @override
  Widget build(BuildContext context) {
    final report = ref.watch(alertReportProvider);
    final today = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Alertas'),
        actions: [
          IconButton(
            tooltip: 'Configurar limiares de alerta',
            icon: const Icon(Icons.tune),
            onPressed: () => context.goNamed(AppRoutes.thresholds),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshTerritoryData(ref),
        child: AsyncValueView(
          value: report,
          errorMessage: 'Não foi possível gerar os alertas.',
          onRetry: () => refreshTerritoryData(ref),
          builder: (report) {
            final alerts = _filter == null
                ? report.alerts
                : report.alerts.where((a) => a.area == _filter).toList();
            return ListView(
              padding: AppSpacing.screen,
              children: [
                const HumanDecisionBanner(),
                const SizedBox(height: AppSpacing.md),
                _AreaFilter(
                  selected: _filter,
                  onChanged: (area) => setState(() => _filter = area),
                ),
                const SizedBox(height: AppSpacing.md),
                for (final note in report.notes)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.md),
                    child: Card(
                      child: ListTile(
                        leading: const Icon(Icons.cloud_off_outlined),
                        title: Text(note),
                      ),
                    ),
                  ),
                if (alerts.isEmpty)
                  EmptyView(
                    scrollable: false,
                    icon: Icons.notifications_none,
                    message: _filter == null
                        ? 'Nenhum alerta com os limiares atuais.'
                        : 'Nenhum alerta em ${_filter!.label.toLowerCase()}.',
                  )
                else ...[
                  Semantics(
                    liveRegion: true,
                    child: Text(
                      '${alerts.length} ${alerts.length == 1 ? 'alerta ativo' : 'alertas ativos'}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  for (final alert in alerts)
                    Padding(
                      padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                      child: AlertTile(alert: alert, today: today),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}

class _AreaFilter extends StatelessWidget {
  const _AreaFilter({required this.selected, required this.onChanged});

  final TerritoryArea? selected;
  final ValueChanged<TerritoryArea?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: AppSpacing.sm,
      runSpacing: AppSpacing.sm,
      children: [
        ChoiceChip(
          label: const Text('Todas'),
          selected: selected == null,
          onSelected: (_) => onChanged(null),
        ),
        for (final area in TerritoryArea.values)
          ChoiceChip(
            avatar: Icon(area.icon, size: 18),
            label: Text(area.label),
            selected: selected == area,
            onSelected: (_) => onChanged(area),
          ),
      ],
    );
  }
}
