import 'dart:math' as math;

import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

import '../../core/domain/indicator.dart';
import '../../core/domain/time_series.dart';
import '../../core/theme/app_spacing.dart';
import '../../core/utils/formatters.dart';

/// Linha de referência (limiar de alerta, capacidade) desenhada no gráfico.
class ReferenceLine {
  const ReferenceLine(this.value, this.label);

  final double value;
  final String label;
}

/// Histórico (linha cheia) + previsão (tracejada) + intervalo de 90%.
///
/// Leitores de tela recebem um resumo em texto em vez do desenho.
class TrendChart extends StatelessWidget {
  const TrendChart({
    super.key,
    required this.indicator,
    this.historyDays = 30,
    this.reference,
    this.height = 220,
  });

  final Indicator indicator;
  final int historyDays;
  final ReferenceLine? reference;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history = _lastDays(indicator.history, historyDays);
    final forecast = indicator.forecast;
    if (history.isEmpty) {
      return const SizedBox.shrink();
    }
    final start = history.first.date;
    double x(DateTime date) => daysBetween(start, date).toDouble();
    final lastHistory = history.last;
    final hasBand = forecast.any((f) => f.hasInterval);

    final values = [
      ...history.map((p) => p.value),
      ...forecast.map((f) => f.upper),
      ...forecast.map((f) => f.lower),
      ?reference?.value,
    ];
    final (minY, maxY) = _bounds(values);
    final endDate = forecast.isEmpty ? lastHistory.date : forecast.last.date;

    LineChartBarData forecastLine(List<FlSpot> spots, {bool band = false}) =>
        LineChartBarData(
          spots: spots,
          color: band ? Colors.transparent : scheme.tertiary,
          barWidth: band ? 0 : 2.5,
          dashArray: band ? null : const [6, 4],
          dotData: const FlDotData(show: false),
        );

    final bars = [
      LineChartBarData(
        spots: [for (final p in history) FlSpot(x(p.date), p.value)],
        color: scheme.primary,
        barWidth: 2.5,
        dotData: const FlDotData(show: false),
      ),
      if (forecast.isNotEmpty) ...[
        forecastLine([
          FlSpot(x(lastHistory.date), lastHistory.value),
          for (final f in forecast) FlSpot(x(f.date), f.value),
        ]),
        if (hasBand) ...[
          forecastLine([
            FlSpot(x(lastHistory.date), lastHistory.value),
            for (final f in forecast) FlSpot(x(f.date), f.upper),
          ], band: true),
          forecastLine([
            FlSpot(x(lastHistory.date), lastHistory.value),
            for (final f in forecast) FlSpot(x(f.date), f.lower),
          ], band: true),
        ],
      ],
    ];

    final chart = LineChart(
      LineChartData(
        minX: 0,
        maxX: x(endDate),
        minY: minY,
        maxY: maxY,
        lineBarsData: bars,
        betweenBarsData: hasBand
            ? [
                BetweenBarsData(
                  fromIndex: 2,
                  toIndex: 3,
                  color: scheme.tertiary.withValues(alpha: 0.18),
                ),
              ]
            : const [],
        extraLinesData: _extraLines(context, reference, forecast, x),
        titlesData: _titles(context, start, indicator.decimals, x(endDate)),
        gridData: _grid(scheme),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            fitInsideHorizontally: true,
            getTooltipItems: (spots) => [
              for (final spot in spots)
                spot.barIndex > 1
                    ? null
                    : LineTooltipItem(
                        '${Fmt.day(addDays(start, spot.x.round()))}\n'
                        '${Fmt.number(spot.y, decimals: indicator.decimals)} '
                        '${indicator.unit}',
                        TextStyle(color: scheme.onInverseSurface),
                      ),
            ],
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: _summary(indicator, history),
          child: ExcludeSemantics(
            child: SizedBox(height: height, child: chart),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Legend(
          items: [
            _LegendItem('Histórico', scheme.primary),
            if (forecast.isNotEmpty)
              _LegendItem('Previsão', scheme.tertiary, dashed: true),
            if (hasBand)
              _LegendItem(
                'Intervalo de 90%',
                scheme.tertiary.withValues(alpha: 0.3),
                area: true,
              ),
            if (reference != null)
              _LegendItem(reference!.label, scheme.error, dashed: true),
          ],
        ),
      ],
    );
  }

  static String _summary(Indicator indicator, List<DataPoint> history) {
    String n(double v) => Fmt.number(v, decimals: indicator.decimals);
    final values = history.map((p) => p.value);
    final parts = [
      'Gráfico de ${indicator.name}.',
      'Nos últimos ${history.length} dias variou de '
          '${n(values.reduce(math.min))} a ${n(values.reduce(math.max))} '
          '${indicator.unit}; último valor ${n(history.last.value)}.',
    ];
    if (indicator.forecast.isNotEmpty) {
      final f = indicator.forecast.map((p) => p.value);
      parts.add(
        'Previsão para os próximos ${indicator.forecast.length} dias entre '
        '${n(f.reduce(math.min))} e ${n(f.reduce(math.max))} '
        '${indicator.unit}.',
      );
    }
    return parts.join(' ');
  }
}

/// Barras diárias (ex.: chuva, solicitações). Previsão em cor mais clara.
class DailyBarChart extends StatelessWidget {
  const DailyBarChart({
    super.key,
    required this.indicator,
    this.historyDays = 21,
    this.reference,
    this.height = 200,
  });

  final Indicator indicator;
  final int historyDays;
  final ReferenceLine? reference;
  final double height;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final history = _lastDays(indicator.history, historyDays);
    if (history.isEmpty) return const SizedBox.shrink();
    final points = [
      for (final p in history) (p.date, p.value, false),
      for (final f in indicator.forecast) (f.date, f.value, true),
    ];
    final start = points.first.$1;
    final (_, maxY) = _bounds([
      ...points.map((p) => p.$2),
      ?reference?.value,
    ], includeZero: true);

    final chart = BarChart(
      BarChartData(
        minY: 0,
        maxY: maxY,
        barGroups: [
          for (final (date, value, isForecast) in points)
            BarChartGroupData(
              x: daysBetween(start, date),
              barRods: [
                BarChartRodData(
                  toY: value,
                  width: math.max(3, 220 / points.length),
                  color: isForecast
                      ? scheme.tertiary.withValues(alpha: 0.75)
                      : scheme.primary,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(2),
                  ),
                ),
              ],
            ),
        ],
        extraLinesData: _extraLines(
          context,
          reference,
          indicator.forecast,
          (date) => daysBetween(start, date).toDouble(),
        ),
        titlesData: _titles(
          context,
          start,
          indicator.decimals,
          (points.length - 1).toDouble(),
        ),
        gridData: _grid(scheme),
        borderData: FlBorderData(show: false),
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipColor: (_) => scheme.inverseSurface,
            fitInsideHorizontally: true,
            getTooltipItem: (group, _, rod, _) => BarTooltipItem(
              '${Fmt.day(addDays(start, group.x))}\n'
              '${Fmt.number(rod.toY, decimals: indicator.decimals)} '
              '${indicator.unit}',
              TextStyle(color: scheme.onInverseSurface),
            ),
          ),
        ),
      ),
    );

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label: TrendChart._summary(indicator, history),
          child: ExcludeSemantics(
            child: SizedBox(height: height, child: chart),
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        _Legend(
          items: [
            _LegendItem('Observado', scheme.primary, area: true),
            if (indicator.forecast.isNotEmpty)
              _LegendItem(
                'Previsão',
                scheme.tertiary.withValues(alpha: 0.75),
                area: true,
              ),
            if (reference != null)
              _LegendItem(reference!.label, scheme.error, dashed: true),
          ],
        ),
      ],
    );
  }
}

/// Uma barra horizontal por setor, com marcador de limiar opcional.
class SectorBars extends StatelessWidget {
  const SectorBars({
    super.key,
    required this.entries,
    required this.maxValue,
    this.threshold,
    this.thresholdLabel,
  });

  final List<SectorBarEntry> entries;
  final double maxValue;
  final double? threshold;
  final String? thresholdLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final scheme = theme.colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (final entry in entries)
          Semantics(
            label:
                '${entry.label}: ${entry.valueText}'
                '${threshold != null && entry.value >= threshold! ? ', acima do limiar' : ''}',
            child: ExcludeSemantics(
              child: Padding(
                padding: const EdgeInsets.only(bottom: AppSpacing.md),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(child: Text(entry.label)),
                        Text(
                          entry.valueText,
                          style: theme.textTheme.labelLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: AppSpacing.xs),
                    LayoutBuilder(
                      builder: (context, constraints) {
                        final width = constraints.maxWidth;
                        final over =
                            threshold != null && entry.value >= threshold!;
                        return SizedBox(
                          height: 12,
                          child: Stack(
                            clipBehavior: Clip.none,
                            children: [
                              Container(
                                decoration: BoxDecoration(
                                  color: scheme.surfaceContainerHighest,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              Container(
                                width:
                                    width *
                                    (entry.value / maxValue).clamp(0.0, 1.0),
                                decoration: BoxDecoration(
                                  color: over ? scheme.error : scheme.primary,
                                  borderRadius: BorderRadius.circular(6),
                                ),
                              ),
                              if (threshold != null)
                                Positioned(
                                  left:
                                      width *
                                          (threshold! / maxValue).clamp(
                                            0.0,
                                            1.0,
                                          ) -
                                      1,
                                  top: -3,
                                  bottom: -3,
                                  child: Container(
                                    width: 2,
                                    color: scheme.onSurface,
                                  ),
                                ),
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            ),
          ),
        if (thresholdLabel != null)
          Row(
            children: [
              Container(width: 2, height: 14, color: scheme.onSurface),
              const SizedBox(width: AppSpacing.sm),
              Text(thresholdLabel!, style: theme.textTheme.bodySmall),
            ],
          ),
      ],
    );
  }
}

class SectorBarEntry {
  const SectorBarEntry({
    required this.label,
    required this.value,
    required this.valueText,
  });

  final String label;
  final double value;
  final String valueText;
}

// ------------------------------------------------------------- apoio

List<DataPoint> _lastDays(List<DataPoint> points, int days) =>
    points.length > days ? points.sublist(points.length - days) : points;

(double, double) _bounds(List<double> values, {bool includeZero = false}) {
  var low = values.reduce(math.min);
  final high = values.reduce(math.max);
  if (includeZero) low = 0;
  final pad = math.max((high - low) * 0.12, high.abs() * 0.02 + 0.5);
  return (includeZero ? 0 : (low - pad), high + pad);
}

ExtraLinesData _extraLines(
  BuildContext context,
  ReferenceLine? reference,
  List<ForecastPoint> forecast,
  double Function(DateTime) x,
) {
  final scheme = Theme.of(context).colorScheme;
  final labelStyle = Theme.of(context).textTheme.labelSmall
      ?.copyWith(color: scheme.onSurfaceVariant);
  return ExtraLinesData(
    horizontalLines: [
      if (reference != null)
        HorizontalLine(
          y: reference.value,
          color: scheme.error,
          strokeWidth: 1.5,
          dashArray: const [4, 4],
        ),
    ],
    verticalLines: [
      if (forecast.isNotEmpty)
        VerticalLine(
          x: x(forecast.first.date),
          color: scheme.outline,
          strokeWidth: 1,
          dashArray: const [2, 3],
          label: VerticalLineLabel(
            show: true,
            alignment: Alignment.topRight,
            style: labelStyle,
            labelResolver: (_) => 'hoje',
          ),
        ),
    ],
  );
}

FlTitlesData _titles(
  BuildContext context,
  DateTime start,
  int decimals,
  double maxX,
) {
  final style = Theme.of(context).textTheme.labelSmall;
  return FlTitlesData(
    topTitles: const AxisTitles(),
    rightTitles: const AxisTitles(),
    leftTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 44,
        getTitlesWidget: (value, meta) {
          if (value == meta.max || value == meta.min) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            child: Text(
              Fmt.number(value, decimals: decimals > 0 && value < 10 ? 1 : 0),
              style: style,
            ),
          );
        },
      ),
    ),
    bottomTitles: AxisTitles(
      sideTitles: SideTitles(
        showTitles: true,
        reservedSize: 28,
        interval: 1,
        getTitlesWidget: (value, meta) {
          // Uma data a cada semana (ou a cada 3 dias em séries curtas), sem
          // sobreposição no fim do eixo.
          final step = maxX > 20 ? 7 : 3;
          final day = value.round();
          if (value != day || day % step != 0 || maxX - day < step / 2) {
            return const SizedBox.shrink();
          }
          return SideTitleWidget(
            meta: meta,
            child: Text(Fmt.day(addDays(start, day)), style: style),
          );
        },
      ),
    ),
  );
}

FlGridData _grid(ColorScheme scheme) => FlGridData(
  drawVerticalLine: false,
  getDrawingHorizontalLine: (_) =>
      FlLine(color: scheme.outlineVariant, strokeWidth: 0.6),
);

class _LegendItem {
  const _LegendItem(
    this.label,
    this.color, {
    this.dashed = false,
    this.area = false,
  });

  final String label;
  final Color color;
  final bool dashed;
  final bool area;
}

class _Legend extends StatelessWidget {
  const _Legend({required this.items});

  final List<_LegendItem> items;

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.bodySmall;
    return ExcludeSemantics(
      child: Wrap(
        spacing: AppSpacing.md,
        runSpacing: AppSpacing.xs,
        children: [
          for (final item in items)
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 18,
                  height: item.area ? 10 : 3,
                  child: item.dashed
                      ? Row(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            Expanded(child: ColoredBox(color: item.color)),
                            const SizedBox(width: 3),
                            Expanded(child: ColoredBox(color: item.color)),
                          ],
                        )
                      : ColoredBox(color: item.color),
                ),
                const SizedBox(width: AppSpacing.xs),
                Text(item.label, style: style),
              ],
            ),
        ],
      ),
    );
  }
}
