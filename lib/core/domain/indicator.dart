import '../analytics/statistics.dart';
import 'territory_area.dart';
import 'time_series.dart';

enum DataOrigin {
  real('Dado real'),
  synthetic('Dado sintético');

  const DataOrigin(this.label);
  final String label;
}

/// Como a previsão de um indicador foi feita e quão bem ela funciona.
class ModelInfo {
  const ModelInfo({
    required this.name,
    required this.description,
    this.r2,
    this.mape,
    this.sampleSize,
    this.intervalLabel,
  });

  final String name;
  final String description;

  /// Quanto da variação o modelo explica (0 a 1).
  final double? r2;

  /// Erro percentual médio no backtest (0,05 = 5%).
  final double? mape;
  final int? sampleSize;
  final String? intervalLabel;
}

/// Indicador do território: série histórica, previsão e metadados.
class Indicator {
  const Indicator({
    required this.id,
    required this.area,
    required this.name,
    required this.unit,
    required this.description,
    required this.origin,
    required this.source,
    required this.history,
    required this.model,
    required this.updatedAt,
    this.forecast = const [],
    this.sectorValues = const {},
    this.sectorValuesLabel,
    this.limitations = const [],
    this.higherIsWorse = true,
    this.decimals = 0,
    this.fromCache = false,
  });

  final String id;
  final TerritoryArea area;
  final String name;
  final String unit;
  final String description;
  final DataOrigin origin;
  final String source;
  final List<DataPoint> history;
  final List<ForecastPoint> forecast;
  final ModelInfo model;
  final DateTime updatedAt;

  /// Valor recente por setor (id do setor → valor), quando houver.
  final Map<String, double> sectorValues;
  final String? sectorValuesLabel;
  final List<String> limitations;

  /// Se subir é ruim (ex.: perdas) ou bom; define a cor da tendência.
  final bool higherIsWorse;
  final int decimals;

  /// Verdadeiro quando os dados vieram do cache local (sem conexão).
  final bool fromCache;

  double get latest => history.last.value;

  /// Variação da média dos últimos 7 dias em relação aos 7 anteriores.
  double? get weeklyChange {
    if (history.length < 14) return null;
    final values = history.map((point) => point.value).toList();
    final last = mean(values.sublist(values.length - 7));
    final previous = mean(
      values.sublist(values.length - 14, values.length - 7),
    );
    if (previous == 0) return null;
    return (last - previous) / previous;
  }
}
