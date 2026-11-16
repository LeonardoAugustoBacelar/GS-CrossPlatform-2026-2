import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/territory_config.dart';
import '../../../core/domain/indicator.dart';
import '../../../core/domain/territory_area.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/refresh.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/human_decision_banner.dart';
import '../../../shared/widgets/section_card.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../alerts/domain/territory_alert.dart';
import '../../alerts/presentation/widgets/alert_widgets.dart';
import '../../climate/application/climate_providers.dart';
import '../../indicators/application/indicators_providers.dart';
import 'widgets/social_impact_card.dart';

/// Visão geral do território: alertas, benefício social e as três áreas.
class OverviewScreen extends ConsumerWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final climate = ref.watch(climateProvider).value;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mirante'),
        actions: [
          IconButton(
            tooltip: 'Mapa do território',
            icon: const Icon(Icons.map_outlined),
            onPressed: () => context.goNamed(AppRoutes.map),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshTerritoryData(ref),
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Semantics(
              header: true,
              child: Text(
                TerritoryConfig.name,
                style: theme.textTheme.headlineMedium,
              ),
            ),
            Text(
              '${TerritoryConfig.region} · '
              '${Fmt.compact(TerritoryConfig.totalPopulation)} moradores em '
              '${TerritoryConfig.sectors.length} setores',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            if (climate != null && climate.fromCache) ...[
              OfflineBanner(savedAt: climate.fetchedAt),
              const SizedBox(height: AppSpacing.md),
            ],
            const HumanDecisionBanner(),
            const SizedBox(height: AppSpacing.md),
            const _AlertsSummary(),
            const SizedBox(height: AppSpacing.md),
            const SocialImpactCard(),
            const SizedBox(height: AppSpacing.lg),
            Semantics(
              header: true,
              child: Text(
                'Áreas do território',
                style: theme.textTheme.titleLarge,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            for (final area in TerritoryArea.values) ...[
              _AreaCard(area: area),
              const SizedBox(height: AppSpacing.sm),
            ],
          ],
        ),
      ),
    );
  }
}

class _AlertsSummary extends ConsumerWidget {
  const _AlertsSummary();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(alertReportProvider);
    final today = ref.watch(clockProvider)();

    return SectionCard(
      title: 'Alertas ativos',
      icon: Icons.notifications_active_outlined,
      trailing: TextButton(
        onPressed: () => context.goNamed(AppRoutes.alerts),
        child: const Text('Ver todos'),
      ),
      child: switch (report) {
        AsyncData(:final value) => Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _SeverityCounts(alerts: value.alerts),
            const SizedBox(height: AppSpacing.md),
            if (value.alerts.isEmpty)
              const Text('Nenhum alerta com os limiares atuais.')
            else
              for (final alert in value.alerts.take(3))
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AlertTile(alert: alert, today: today),
                ),
          ],
        ),
        AsyncError() => const Text('Não foi possível gerar os alertas.'),
        _ => const Padding(
          padding: EdgeInsets.symmetric(vertical: AppSpacing.md),
          child: LinearProgressIndicator(),
        ),
      },
    );
  }
}

class _SeverityCounts extends StatelessWidget {
  const _SeverityCounts({required this.alerts});

  final List<TerritoryAlert> alerts;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        for (final severity in AlertSeverity.values.reversed)
          Expanded(
            child: Semantics(
              label:
                  '${alerts.where((a) => a.severity == severity).length} '
                  'alertas de nível ${severity.label}',
              child: ExcludeSemantics(
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          severity.icon,
                          color: severity.color(context),
                          size: 20,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Text(
                          '${alerts.where((a) => a.severity == severity).length}',
                          style: theme.textTheme.headlineSmall?.copyWith(
                            color: severity.color(context),
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                    Text(severity.label, style: theme.textTheme.labelMedium),
                  ],
                ),
              ),
            ),
          ),
      ],
    );
  }
}

class _AreaCard extends ConsumerWidget {
  const _AreaCard({required this.area});

  final TerritoryArea area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicators = ref.watch(areaIndicatorsProvider(area));
    final headline = switch (indicators) {
      AsyncData(:final value) when value.isNotEmpty => _headline(value.first),
      AsyncError() => 'Sem dados agora',
      _ => 'Carregando…',
    };

    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Icon(area.icon, size: 32),
        title: Text(area.label),
        subtitle: Text('${area.description}\n$headline'),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.goNamed(
          AppRoutes.dashboard,
          pathParameters: {'area': area.name},
        ),
      ),
    );
  }

  /// Número de destaque de cada área (o primeiro indicador dela).
  String _headline(Indicator first) => switch (area) {
    TerritoryArea.clima =>
      'Máxima hoje: ${Fmt.number(first.forecast.isEmpty ? first.latest : first.forecast.first.value, decimals: 1)} °C',
    TerritoryArea.recursos =>
      'Água: ${Fmt.number(first.latest)} L por habitante/dia',
    TerritoryArea.servicos =>
      'Ocupação prevista das UBS: ${Fmt.percent(first.forecast.map((f) => f.value).fold(0.0, math.max) / TerritoryConfig.totalHealthCapacity)}',
  };
}
