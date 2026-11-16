import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/config/territory_config.dart';
import '../../../../core/domain/time_series.dart';
import '../../../../core/providers.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/formatters.dart';
import '../../../../shared/widgets/kpi_tile.dart';
import '../../../../shared/widgets/section_card.dart';
import '../../../alerts/application/alerts_providers.dart';
import '../../../indicators/application/indicators_providers.dart';
import '../../../indicators/domain/indicator_ids.dart';
import '../../../occurrences/application/occurrences_controller.dart';

/// Indicadores de benefício social: liga o desempenho da análise (erro das
/// previsões, antecedência) ao que ele significa para os moradores.
class SocialImpactCard extends ConsumerWidget {
  const SocialImpactCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(alertReportProvider).value;
    final decisions = ref.watch(decisionsProvider);
    final reports = ref.watch(occurrencesProvider).length;
    final water = ref
        .watch(availableIndicatorsProvider)
        .value?[IndicatorIds.water];
    final today = ref.watch(clockProvider)();
    final alerts = report?.alerts ?? const [];

    final coveredSectors = {for (final a in alerts) ...a.sectorIds};
    final covered = TerritoryConfig.sectors
        .where((s) => coveredSectors.contains(s.id))
        .fold(0, (sum, s) => sum + s.population);
    final ahead = [
      for (final a in alerts)
        if (a.expectedDate.isAfter(dateOnly(today)))
          daysBetween(today, a.expectedDate),
    ];
    final recoverable = alerts.fold(
      0.0,
      (sum, a) => sum + (a.recoverableLitersPerDay ?? 0),
    );
    final decided = alerts.where((a) => decisions.containsKey(a.id)).length;

    return SectionCard(
      title: 'Benefício social',
      subtitle: 'O que a análise significa para quem mora no território',
      icon: Icons.volunteer_activism_outlined,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          KpiGrid(
            children: [
              _AnimatedKpi(
                label: 'Moradores em áreas com alerta',
                value: covered.toDouble(),
                format: Fmt.compact,
              ),
              KpiTile(
                label: 'Antecedência média',
                value: ahead.isEmpty
                    ? '—'
                    : Fmt.number(
                        ahead.reduce((a, b) => a + b) / ahead.length,
                        decimals: 1,
                      ),
                unit: ahead.isEmpty ? null : 'dias',
                caption: 'para se preparar antes do problema',
              ),
              _AnimatedKpi(
                label: 'Água recuperável',
                value: recoverable,
                format: (v) => '${Fmt.compact(v)} L/dia',
                caption: 'se os vazamentos indicados forem corrigidos',
              ),
              KpiTile(
                label: 'Decisões registradas',
                value: '$decided de ${alerts.length}',
                caption: 'alertas avaliados por uma pessoa',
              ),
              KpiTile(
                label: 'Relatos de cidadãos',
                value: '$reports',
                caption: 'sinais vindos dos moradores',
              ),
            ],
          ),
          if (water?.model.mape != null) ...[
            const SizedBox(height: AppSpacing.md),
            Text(
              'A previsão de consumo de água erra em média '
              '${Fmt.percent(water!.model.mape!, decimals: 1)}. Quanto menor '
              'o erro, mais cedo e com mais segurança a equipe pode agir para '
              'evitar falta d’água.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

/// KPI cujo número sobe animado até o valor, para chamar atenção à mudança.
class _AnimatedKpi extends StatelessWidget {
  const _AnimatedKpi({
    required this.label,
    required this.value,
    required this.format,
    this.caption,
  });

  final String label;
  final double value;
  final String Function(double) format;
  final String? caption;

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: MediaQuery.disableAnimationsOf(context)
          ? Duration.zero
          : const Duration(milliseconds: 800),
      curve: Curves.easeOutCubic,
      builder: (context, current, _) =>
          KpiTile(label: label, value: format(current), caption: caption),
    );
  }
}
