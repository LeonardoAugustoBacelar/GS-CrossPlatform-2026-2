import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/config/territory_config.dart';
import '../../../core/domain/territory_area.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/kpi_tile.dart';
import '../../../shared/widgets/section_card.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../alerts/domain/alert_thresholds.dart';
import '../../indicators/domain/indicator_ids.dart';
import '../../occurrences/application/occurrences_controller.dart';
import 'dashboard_scaffold.dart';

/// Dashboard 3: serviços públicos (UBS e coleta) + relatos dos cidadãos.
class ServicesDashboardScreen extends ConsumerWidget {
  const ServicesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final occupancyLimit = ref.watch(
      thresholdsProvider,
    )[ThresholdField.healthOccupancy];
    final reports = ref.watch(occurrencesProvider).length;

    return DashboardScaffold(
      area: TerritoryArea.servicos,
      builder: (context, indicators) {
        final health = indicators[IndicatorIds.health]!;
        final waste = indicators[IndicatorIds.waste]!;
        final capacity = TerritoryConfig.totalHealthCapacity.toDouble();
        final peakForecast = health.forecast
            .map((f) => f.value)
            .fold(0.0, math.max);

        return [
          KpiGrid(
            children: [
              KpiTile(
                label: 'Atendimentos nas UBS',
                value: Fmt.number(
                  health.sectorValues.values.fold(0.0, (a, b) => a + b),
                ),
                unit: 'por dia útil',
                change: health.weeklyChange,
                onTap: () => openIndicator(context, health),
              ),
              KpiTile(
                label: 'Ocupação prevista (pico)',
                value: Fmt.percent(peakForecast / capacity),
                caption: 'da capacidade total nos próximos 7 dias',
                onTap: () => openIndicator(context, health),
              ),
              KpiTile(
                label: 'Solicitações de coleta',
                value: Fmt.number(
                  waste.sectorValues.values.fold(0.0, (a, b) => a + b),
                  decimals: 1,
                ),
                unit: 'por dia',
                change: waste.weeklyChange,
                onTap: () => openIndicator(context, waste),
              ),
              KpiTile(
                label: 'Relatos de cidadãos',
                value: Fmt.number(reports),
                caption: 'registrados neste aparelho',
                higherIsWorse: false,
              ),
            ],
          ),
          SectionCard(
            title: 'Atendimentos nas UBS',
            subtitle: 'Total do território e previsão com tendência',
            icon: Icons.local_hospital_outlined,
            child: Column(
              children: [
                TrendChart(
                  indicator: health,
                  reference: ReferenceLine(capacity, 'Capacidade diária'),
                ),
                IndicatorDetailsButton(indicator: health),
              ],
            ),
          ),
          SectionCard(
            title: 'Ocupação das UBS por setor',
            subtitle: 'Média dos últimos 5 dias úteis sobre a capacidade',
            icon: Icons.groups_outlined,
            child: SectorBars(
              maxValue: 120,
              threshold: occupancyLimit,
              thresholdLabel: 'Limiar: ${Fmt.number(occupancyLimit)}%',
              entries: [
                for (final sector in TerritoryConfig.sectors)
                  () {
                    final occupancy =
                        health.sectorValues[sector.id]! /
                        sector.healthDailyCapacity *
                        100;
                    return SectorBarEntry(
                      label: sector.name,
                      value: occupancy,
                      valueText: '${Fmt.number(occupancy)}%',
                    );
                  }(),
              ],
            ),
          ),
          SectionCard(
            title: 'Solicitações de coleta e descarte irregular',
            subtitle: 'Total diário do território',
            icon: Icons.delete_outline,
            child: Column(
              children: [
                DailyBarChart(indicator: waste),
                IndicatorDetailsButton(indicator: waste),
              ],
            ),
          ),
        ];
      },
    );
  }
}
