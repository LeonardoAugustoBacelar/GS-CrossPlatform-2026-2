import '../../../core/analytics/forecasting.dart';
import '../../../core/analytics/statistics.dart';
import '../../../core/domain/indicator.dart';
import '../../../core/domain/territory_area.dart';
import '../../../core/domain/time_series.dart';
import '../../climate/domain/climate_snapshot.dart';
import '../../territory_data/data/synthetic_territory_api.dart';
import '../../territory_data/domain/territory_dataset.dart';
import 'indicator_ids.dart';

/// Monta os indicadores de cada área a partir dos dados brutos.
abstract final class IndicatorBuilder {
  static const _syntheticLimitation =
      'Dados sintéticos gerados para fins acadêmicos: mostram o método, '
      'não a situação real do território.';

  static List<Indicator> climate(ClimateSnapshot climate, DateTime today) {
    final day0 = dateOnly(today);
    final past = climate.days.where((d) => d.date.isBefore(day0)).toList();
    final future = climate.days.where((d) => !d.date.isBefore(day0)).toList();
    const source = 'Open-Meteo (dados abertos)';
    const forecastModel = ModelInfo(
      name: 'Previsão numérica Open-Meteo',
      description:
          'Combinação de modelos meteorológicos globais e regionais escolhida '
          'automaticamente pela Open-Meteo para o ponto do território. O app '
          'não ajusta modelo próprio para o clima: usa a previsão oficial e '
          'aplica as regras de alerta sobre ela.',
    );

    final indicators = [
      Indicator(
        id: IndicatorIds.temperature,
        area: TerritoryArea.clima,
        name: 'Temperatura máxima',
        unit: '°C',
        description: 'Máxima diária no centro do território.',
        origin: DataOrigin.real,
        source: source,
        history: [for (final d in past) DataPoint(d.date, d.tempMax)],
        forecast: [
          for (final d in future) ForecastPoint(date: d.date, value: d.tempMax),
        ],
        model: forecastModel,
        updatedAt: climate.fetchedAt,
        fromCache: climate.fromCache,
        decimals: 1,
        limitations: const [
          'Resolução de alguns quilômetros: não capta ilhas de calor de ruas.',
          'Não considera a umidade, que muda a sensação térmica.',
        ],
      ),
      Indicator(
        id: IndicatorIds.rain,
        area: TerritoryArea.clima,
        name: 'Chuva diária',
        unit: 'mm',
        description: 'Chuva acumulada no dia.',
        origin: DataOrigin.real,
        source: source,
        history: [for (final d in past) DataPoint(d.date, d.precipitation)],
        forecast: [
          for (final d in future)
            ForecastPoint(date: d.date, value: d.precipitation),
        ],
        model: forecastModel,
        updatedAt: climate.fetchedAt,
        fromCache: climate.fromCache,
        decimals: 1,
        limitations: const [
          'Chuva de verão é muito localizada: pode variar entre bairros vizinhos.',
        ],
      ),
    ];

    if (climate.hasAirQuality) {
      indicators.add(
        Indicator(
          id: IndicatorIds.airQuality,
          area: TerritoryArea.clima,
          name: 'Partículas finas (PM2,5)',
          unit: 'µg/m³',
          description: 'Média diária de partículas finas no ar.',
          origin: DataOrigin.real,
          source: 'Open-Meteo, modelo CAMS (dados abertos)',
          history: [
            for (final d in past)
              if (d.pm25 != null) DataPoint(d.date, d.pm25!),
          ],
          forecast: [
            for (final d in future)
              if (d.pm25 != null) ForecastPoint(date: d.date, value: d.pm25!),
          ],
          model: const ModelInfo(
            name: 'Previsão CAMS (Copernicus) via Open-Meteo',
            description:
                'Modelo europeu de composição da atmosfera. Estima a poluição '
                'em grade regional, não por estação de medição.',
          ),
          updatedAt: climate.fetchedAt,
          fromCache: climate.fromCache,
          decimals: 1,
          limitations: const [
            'Estimativa de modelo, não medição de estação da CETESB.',
            'Queimadas e obras locais podem não aparecer.',
          ],
        ),
      );
    }
    return indicators;
  }

  static List<Indicator> resources(TerritoryDataset data, DateTime today) {
    final future = _futureDates(today);

    final water = data.populationWeighted(SeriesId.water);
    final waterForecast = regressionForecast(
      history: water,
      futureDates: future,
      features: (date, _) => [1, data.tempMaxOn(date), isWeekend(date) ? 1 : 0],
      modelName: 'Regressão linear: temperatura + fim de semana',
      modelDescription:
          'Ajustada nos últimos 60 dias. Explica o consumo por habitante a '
          'partir da temperatura máxima do dia e de ser fim de semana. Para '
          'prever, usa a temperatura máxima prevista pela Open-Meteo.',
    );

    final loss = data.populationWeighted(SeriesId.waterLoss);
    final recentLoss = loss.sublist(loss.length - 21);
    final lossForecast = regressionForecast(
      history: recentLoss,
      futureDates: future,
      features: (_, index) => [1, index.toDouble()],
      modelName: 'Tendência linear (21 dias)',
      modelDescription:
          'Reta ajustada nas últimas três semanas. Serve para mostrar a '
          'direção da série; os alertas de perdas usam detecção de anomalia.',
      backtestDays: 7,
    );

    final energy = data.total(SeriesId.energy);
    final energyForecast = regressionForecast(
      history: energy,
      futureDates: future,
      features: (date, _) => [1, data.tempMaxOn(date), isWeekend(date) ? 1 : 0],
      modelName: 'Regressão linear: temperatura + fim de semana',
      modelDescription:
          'Mesmo método do consumo de água: calor aumenta o uso de '
          'ventiladores e geladeiras, e o fim de semana muda a rotina.',
    );

    final limitations = [
      _syntheticLimitation,
      if (!data.tempMaxIsReal)
        'Sem clima real disponível: o fator de temperatura usa uma média '
            'histórica, o que reduz a precisão.',
    ];

    return [
      Indicator(
        id: IndicatorIds.water,
        area: TerritoryArea.recursos,
        name: 'Consumo de água',
        unit: 'L/hab/dia',
        description: 'Litros consumidos por habitante por dia.',
        origin: DataOrigin.synthetic,
        source: data.source,
        history: water,
        forecast: waterForecast.points,
        model: waterForecast.model,
        updatedAt: data.dates.last,
        sectorValues: _sectorRecentMean(data, SeriesId.water),
        sectorValuesLabel: 'Média dos últimos 7 dias por setor',
        limitations: limitations,
      ),
      Indicator(
        id: IndicatorIds.waterLoss,
        area: TerritoryArea.recursos,
        name: 'Perdas na distribuição',
        unit: '%',
        description: 'Água tratada que se perde antes de chegar às casas.',
        origin: DataOrigin.synthetic,
        source: data.source,
        history: loss,
        forecast: lossForecast.points,
        model: lossForecast.model,
        updatedAt: data.dates.last,
        sectorValues: _sectorRecentMean(data, SeriesId.waterLoss),
        sectorValuesLabel: 'Média dos últimos 7 dias por setor',
        decimals: 1,
        limitations: [
          ...limitations,
          'Perda aparente mistura vazamentos, ligações irregulares e erro '
              'de medição.',
        ],
      ),
      Indicator(
        id: IndicatorIds.energy,
        area: TerritoryArea.recursos,
        name: 'Consumo de energia',
        unit: 'MWh/dia',
        description: 'Energia elétrica residencial consumida por dia.',
        origin: DataOrigin.synthetic,
        source: data.source,
        history: energy,
        forecast: energyForecast.points,
        model: energyForecast.model,
        updatedAt: data.dates.last,
        sectorValues: _sectorRecentMean(data, SeriesId.energy),
        sectorValuesLabel: 'Média dos últimos 7 dias por setor',
        limitations: limitations,
      ),
    ];
  }

  static List<Indicator> services(TerritoryDataset data, DateTime today) {
    final future = _futureDates(today);

    final health = data.total(SeriesId.health);
    final healthForecast = healthForecastFor(health, future);

    final waste = data.total(SeriesId.waste);
    final recentWaste = waste.sublist(waste.length - 35);
    final wasteForecast = regressionForecast(
      history: recentWaste,
      futureDates: future,
      features: (date, index) => [1, index.toDouble(), isWeekend(date) ? 1 : 0],
      modelName: 'Regressão linear: tendência + fim de semana',
      modelDescription:
          'Ajustada nas últimas 5 semanas. Captura a direção recente das '
          'solicitações e a queda típica nos fins de semana.',
      backtestDays: 7,
    );

    return [
      Indicator(
        id: IndicatorIds.health,
        area: TerritoryArea.servicos,
        name: 'Atendimentos nas UBS',
        unit: 'atendimentos/dia',
        description: 'Total de atendimentos nas Unidades Básicas de Saúde.',
        origin: DataOrigin.synthetic,
        source: data.source,
        history: health,
        forecast: healthForecast.points,
        model: healthForecast.model,
        updatedAt: data.dates.last,
        sectorValues: _sectorRecentMean(
          data,
          SeriesId.health,
          weekdaysOnly: true,
        ),
        sectorValuesLabel: 'Média dos últimos 5 dias úteis por setor',
        limitations: const [
          _syntheticLimitation,
          'Surtos (dengue, gripe) podem acelerar a demanda além da tendência.',
          'Não diferencia tipos de atendimento nem gravidade.',
        ],
      ),
      Indicator(
        id: IndicatorIds.waste,
        area: TerritoryArea.servicos,
        name: 'Solicitações de coleta',
        unit: 'solicitações/dia',
        description:
            'Pedidos de remoção de lixo e denúncias de descarte irregular.',
        origin: DataOrigin.synthetic,
        source: data.source,
        history: waste,
        forecast: wasteForecast.points,
        model: wasteForecast.model,
        updatedAt: data.dates.last,
        sectorValues: _sectorRecentMean(data, SeriesId.waste),
        sectorValuesLabel: 'Média dos últimos 7 dias por setor',
        decimals: 1,
        limitations: const [
          _syntheticLimitation,
          'Viés de notificação: bairros que reclamam menos parecem melhores '
              'do que estão.',
        ],
      ),
    ];
  }

  /// Previsão de atendimentos: tendência + sábado + domingo (últimas 5 semanas).
  /// Também usada pelo motor de alertas, setor a setor.
  static ForecastResult healthForecastFor(
    List<DataPoint> history,
    List<DateTime> futureDates,
  ) {
    final recent = history.sublist(history.length - 35);
    return regressionForecast(
      history: recent,
      futureDates: futureDates,
      features: (date, index) => [
        1,
        index.toDouble(),
        date.weekday == DateTime.saturday ? 1 : 0,
        date.weekday == DateTime.sunday ? 1 : 0,
      ],
      modelName: 'Regressão linear: tendência + dia da semana',
      modelDescription:
          'Ajustada nas últimas 5 semanas. Separa a tendência de alta ou '
          'queda do movimento menor aos sábados e domingos.',
      backtestDays: 7,
    );
  }

  static List<DateTime> _futureDates(DateTime today) => [
    for (var i = 0; i < SyntheticTerritoryApi.forecastDays; i++)
      addDays(today, i),
  ];

  static Map<String, double> _sectorRecentMean(
    TerritoryDataset data,
    String seriesId, {
    bool weekdaysOnly = false,
  }) {
    return {
      for (final entry in data.series[seriesId]!.entries)
        entry.key: mean(
          [
            for (var i = 0; i < data.dates.length; i++)
              if (!weekdaysOnly || !isWeekend(data.dates[i])) entry.value[i],
          ].reversed.take(weekdaysOnly ? 5 : 7),
        ),
    };
  }
}
