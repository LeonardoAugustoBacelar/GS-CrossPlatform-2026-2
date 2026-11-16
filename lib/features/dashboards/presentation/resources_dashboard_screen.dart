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
import 'dashboard_scaffold.dart';

/// Dashboard 2: água e energia (dados sintéticos da API simulada).
class ResourcesDashboardScreen extends ConsumerWidget {
  const ResourcesDashboardScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lossLimit = ref.watch(thresholdsProvider)[ThresholdField.waterLoss];
    return DashboardScaffold(
      area: TerritoryArea.recursos,
      builder: (context, indicators) {
        final water = indicators[IndicatorIds.water]!;
        final loss = indicators[IndicatorIds.waterLoss]!;
        final energy = indicators[IndicatorIds.energy]!;

        return [
          KpiGrid(
            children: [
              KpiTile(
                label: 'Água por habitante',
                value: Fmt.number(water.latest),
                unit: 'L/dia',
                change: water.weeklyChange,
                onTap: () => openIndicator(context, water),
              ),
              KpiTile(
                label: 'Perdas na distribuição',
                value: Fmt.number(loss.latest, decimals: 1),
                unit: '%',
                change: loss.weeklyChange,
                onTap: () => openIndicator(context, loss),
              ),
              KpiTile(
                label: 'Energia residencial',
                value: Fmt.number(energy.latest),
                unit: 'MWh/dia',
                change: energy.weeklyChange,
                onTap: () => openIndicator(context, energy),
              ),
            ],
          ),
          SectionCard(
            title: 'Consumo de água por habitante',
            subtitle: 'Previsão por regressão com a temperatura prevista',
            icon: Icons.water_drop_outlined,
            child: Column(
              children: [
                TrendChart(indicator: water),
                IndicatorDetailsButton(indicator: water),
              ],
            ),
          ),
          SectionCard(
            title: 'Perdas de água por setor',
            subtitle: loss.sectorValuesLabel,
            icon: Icons.plumbing,
            child: Column(
              children: [
                SectorBars(
                  maxValue: 50,
                  threshold: lossLimit,
                  thresholdLabel: 'Limiar: ${Fmt.number(lossLimit)}%',
                  entries: [
                    for (final sector in TerritoryConfig.sectors)
                      SectorBarEntry(
                        label: sector.name,
                        value: loss.sectorValues[sector.id]!,
                        valueText:
                            '${Fmt.number(loss.sectorValues[sector.id]!, decimals: 1)}%',
                      ),
                  ],
                ),
                IndicatorDetailsButton(indicator: loss),
              ],
            ),
          ),
          SectionCard(
            title: 'Consumo de energia',
            subtitle: 'Total residencial do território',
            icon: Icons.bolt_outlined,
            child: Column(
              children: [
                TrendChart(indicator: energy),
                IndicatorDetailsButton(indicator: energy),
              ],
            ),
          ),
        ];
      },
    );
  }
}
