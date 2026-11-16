import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/domain/territory_area.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/charts.dart';
import '../../../shared/widgets/kpi_tile.dart';
import '../../../shared/widgets/section_card.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../alerts/domain/alert_thresholds.dart';
import '../../indicators/domain/indicator_ids.dart';
import 'dashboard_scaffold.dart';

/// Dashboard 1: clima local com dados reais (temperatura, chuva, ar).
class ClimateDashboardScreen extends ConsumerWidget {
  const ClimateDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final thresholds = ref.watch(thresholdsProvider);
    return DashboardScaffold(
      area: TerritoryArea.clima,
      errorMessage:
          'Sem conexão e sem dados de clima salvos. Conecte-se à internet '
          'uma vez para que o app guarde uma cópia para uso offline.',
      builder: (context, indicators) {
        final temperature = indicators[IndicatorIds.temperature]!;
        final rain = indicators[IndicatorIds.rain]!;
        final air = indicators[IndicatorIds.airQuality];
        final rainNext7 = rain.forecast.fold(0.0, (sum, f) => sum + f.value);

        return [
          KpiGrid(
            children: [
              KpiTile(
                label: 'Máxima hoje',
                value: Fmt.number(
                  temperature.forecast.isEmpty
                      ? temperature.latest
                      : temperature.forecast.first.value,
                  decimals: 1,
                ),
                unit: '°C',
                change: temperature.weeklyChange,
                onTap: () => openIndicator(context, temperature),
              ),
              KpiTile(
                label: 'Chuva nos próximos 7 dias',
                value: Fmt.number(rainNext7, decimals: 1),
                unit: 'mm',
                onTap: () => openIndicator(context, rain),
              ),
              if (air != null)
                KpiTile(
                  label: 'PM2,5 hoje',
                  value: Fmt.number(
                    air.forecast.isEmpty
                        ? air.latest
                        : air.forecast.first.value,
                    decimals: 1,
                  ),
                  unit: 'µg/m³',
                  change: air.weeklyChange,
                  onTap: () => openIndicator(context, air),
                ),
            ],
          ),
          SectionCard(
            title: 'Temperatura máxima',
            subtitle: 'Últimos 30 dias e previsão para 7 dias',
            icon: Icons.thermostat_outlined,
            child: Column(
              children: [
                TrendChart(
                  indicator: temperature,
                  reference: ReferenceLine(
                    thresholds[ThresholdField.heatTemperature],
                    'Limiar de calor',
                  ),
                ),
                IndicatorDetailsButton(indicator: temperature),
              ],
            ),
          ),
          SectionCard(
            title: 'Chuva diária',
            subtitle: 'Últimas 3 semanas e previsão',
            icon: Icons.water_outlined,
            child: Column(
              children: [
                DailyBarChart(
                  indicator: rain,
                  reference: ReferenceLine(
                    thresholds[ThresholdField.rainMm],
                    'Limiar de chuva forte',
                  ),
                ),
                IndicatorDetailsButton(indicator: rain),
              ],
            ),
          ),
          if (air != null)
            SectionCard(
              title: 'Qualidade do ar',
              subtitle: 'Partículas finas (PM2,5), média diária',
              icon: Icons.air,
              child: Column(
                children: [
                  TrendChart(
                    indicator: air,
                    reference: ReferenceLine(
                      thresholds[ThresholdField.pm25],
                      'Limiar de PM2,5',
                    ),
                  ),
                  IndicatorDetailsButton(indicator: air),
                ],
              ),
            ),
        ];
      },
    );
  }
}
