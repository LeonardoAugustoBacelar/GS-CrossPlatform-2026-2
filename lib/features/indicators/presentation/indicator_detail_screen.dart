import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/territory_config.dart';
import '../../../core/domain/indicator.dart';
import '../../../core/providers.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/refresh.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/kpi_tile.dart';
import '../../../shared/widgets/origin_chip.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../alerts/presentation/widgets/alert_widgets.dart';
import '../application/indicators_providers.dart';

/// Detalhe de um indicador: série longa, como a previsão é feita, valores
/// por setor, limitações e os alertas ligados a ele.
class IndicatorDetailScreen extends ConsumerWidget {
  const IndicatorDetailScreen({super.key, required this.indicatorId});

  final String indicatorId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicator = ref.watch(indicatorProvider(indicatorId));
    return Scaffold(
      appBar: AppBar(title: const Text('Indicador')),
      body: AsyncValueView<Indicator?>(
        value: indicator,
        onRetry: () => refreshTerritoryData(ref),
        builder: (indicator) => indicator == null
            ? const EmptyView(
                icon: Icons.search_off,
                message:
                    'Indicador indisponível agora. Verifique a conexão e '
                    'tente atualizar.',
              )
            : _IndicatorDetail(indicator: indicator),
      ),
    );
  }
}

class _IndicatorDetail extends ConsumerWidget {
  const _IndicatorDetail({required this.indicator});

  final Indicator indicator;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(clockProvider)();
    final model = indicator.model;
    String n(double v) => Fmt.number(v, decimals: indicator.decimals);
    final forecastValues = indicator.forecast.map((f) => f.value);

    return ListView(
      padding: AppSpacing.screen,
      children: [
        if (indicator.fromCache) ...[
          OfflineBanner(savedAt: indicator.updatedAt),
          const SizedBox(height: AppSpacing.md),
        ],
        Semantics(
          header: true,
          child: Text(indicator.name, style: theme.textTheme.headlineSmall),
        ),
        const SizedBox(height: AppSpacing.xs),
        Text(indicator.description),
        const SizedBox(height: AppSpacing.sm),
        Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.xs,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            OriginChip(origin: indicator.origin),
            Text(indicator.source, style: theme.textTheme.bodySmall),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        KpiGrid(
          children: [
            KpiTile(
              label: 'Último valor',
              value: n(indicator.latest),
              unit: indicator.unit,
              change: indicator.weeklyChange,
              higherIsWorse: indicator.higherIsWorse,
            ),
            if (forecastValues.isNotEmpty)
              KpiTile(
                label: 'Previsão (7 dias)',
                value:
                    '${n(forecastValues.reduce(math.min))} a '
                    '${n(forecastValues.reduce(math.max))}',
                unit: indicator.unit,
              ),
          ],
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Histórico e previsão',
          subtitle: 'Últimos 60 dias',
          icon: Icons.show_chart,
          child: TrendChart(indicator: indicator, historyDays: 60, height: 260),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Como a previsão é feita',
          icon: Icons.model_training,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(model.name, style: theme.textTheme.titleSmall),
              const SizedBox(height: AppSpacing.xs),
              Text(model.description),
              if (model.r2 != null || model.mape != null) ...[
                const SizedBox(height: AppSpacing.md),
                KpiGrid(
                  children: [
                    if (model.r2 != null)
                      KpiTile(
                        label: 'R² (ajuste)',
                        value: Fmt.number(model.r2!, decimals: 2),
                        caption: 'Quanto da variação o modelo explica (0 a 1).',
                      ),
                    if (model.mape != null)
                      KpiTile(
                        label: 'Erro médio (backtest)',
                        value: Fmt.percent(model.mape!, decimals: 1),
                        caption:
                            'Diferença média entre previsto e real nos '
                            'últimos dias, escondidos do modelo.',
                      ),
                    if (model.sampleSize != null)
                      KpiTile(
                        label: 'Dias usados',
                        value: '${model.sampleSize}',
                        caption: 'Tamanho da amostra do ajuste.',
                      ),
                  ],
                ),
              ],
              if (model.intervalLabel != null) ...[
                const SizedBox(height: AppSpacing.sm),
                Text(model.intervalLabel!, style: theme.textTheme.bodySmall),
              ],
            ],
          ),
        ),
        if (indicator.sectorValues.isNotEmpty) ...[
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Por setor',
            subtitle: indicator.sectorValuesLabel,
            icon: Icons.map_outlined,
            child: SectorBars(
              maxValue: indicator.sectorValues.values.reduce(math.max) * 1.15,
              entries: [
                for (final sector in TerritoryConfig.sectors)
                  SectorBarEntry(
                    label: sector.name,
                    value: indicator.sectorValues[sector.id]!,
                    valueText:
                        '${n(indicator.sectorValues[sector.id]!)} ${indicator.unit}',
                  ),
              ],
            ),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Limitações dos dados',
          icon: Icons.report_problem_outlined,
          child: BulletList(
            items: indicator.limitations,
            icon: Icons.remove,
            iconSize: 18,
            iconColor: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        _RelatedAlerts(indicatorId: indicator.id, today: today),
        SourceNote(
          text:
              'Fonte: ${indicator.source}. Dados até '
              '${Fmt.day(indicator.history.last.date)}.',
        ),
      ],
    );
  }
}

class _RelatedAlerts extends ConsumerWidget {
  const _RelatedAlerts({required this.indicatorId, required this.today});

  final String indicatorId;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alerts = ref
        .watch(alertReportProvider)
        .value
        ?.alerts
        .where((a) => a.indicatorId == indicatorId)
        .toList();
    return SectionCard(
      title: 'Alertas ligados a este indicador',
      icon: Icons.notifications_active_outlined,
      child: alerts == null
          ? const LinearProgressIndicator()
          : alerts.isEmpty
          ? const Text('Nenhum alerta ativo com os limiares atuais.')
          : Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                for (final alert in alerts)
                  Padding(
                    padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                    child: AlertTile(alert: alert, today: today),
                  ),
              ],
            ),
    );
  }
}
