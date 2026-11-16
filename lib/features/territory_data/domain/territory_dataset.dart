import '../../../core/config/territory_config.dart';
import '../../../core/domain/time_series.dart';

/// Séries diárias por setor recebidas da API simulada.
class TerritoryDataset {
  const TerritoryDataset({
    required this.source,
    required this.dates,
    required this.series,
    required this.tempMax,
    required this.tempMaxIsReal,
  });

  factory TerritoryDataset.fromJson(Map<String, dynamic> json) {
    final rawSeries = json['series'] as Map<String, dynamic>;
    return TerritoryDataset(
      source: json['source'] as String,
      dates: [
        for (final key in (json['dates'] as List).cast<String>())
          parseDateKey(key),
      ],
      series: {
        for (final entry in rawSeries.entries)
          entry.key: {
            for (final sector in (entry.value as Map<String, dynamic>).entries)
              sector.key: [
                for (final v in sector.value as List) (v as num).toDouble(),
              ],
          },
      },
      tempMax: {
        for (final entry in (json['tempMax'] as Map<String, dynamic>).entries)
          entry.key: (entry.value as num).toDouble(),
      },
      tempMaxIsReal: json['tempMaxIsReal'] as bool,
    );
  }

  final String source;

  /// Datas do histórico, em ordem crescente (terminam ontem).
  final List<DateTime> dates;

  /// série → setor → valores alinhados com [dates].
  final Map<String, Map<String, List<double>>> series;

  /// Temperatura máxima usada como fator (histórico + próximos dias).
  final Map<String, double> tempMax;
  final bool tempMaxIsReal;

  List<DataPoint> sectorSeries(String seriesId, String sectorId) {
    final values = series[seriesId]![sectorId]!;
    return [
      for (var i = 0; i < dates.length; i++) DataPoint(dates[i], values[i]),
    ];
  }

  /// Soma dos setores (ex.: energia total, atendimentos totais).
  List<DataPoint> total(String seriesId) {
    final bySector = series[seriesId]!;
    return [
      for (var i = 0; i < dates.length; i++)
        DataPoint(
          dates[i],
          bySector.values.fold(0.0, (sum, values) => sum + values[i]),
        ),
    ];
  }

  /// Média ponderada pela população (ex.: litros por habitante, perdas %).
  List<DataPoint> populationWeighted(String seriesId) {
    final bySector = series[seriesId]!;
    final population = TerritoryConfig.totalPopulation;
    return [
      for (var i = 0; i < dates.length; i++)
        DataPoint(
          dates[i],
          TerritoryConfig.sectors.fold(
                0.0,
                (sum, sector) =>
                    sum + bySector[sector.id]![i] * sector.population,
              ) /
              population,
        ),
    ];
  }

  double tempMaxOn(DateTime date) => tempMax[dateKey(date)] ?? 25;
}
