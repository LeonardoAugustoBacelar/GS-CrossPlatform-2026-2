import 'dart:math' as math;

import '../../../core/analytics/linear_regression.dart';
import '../../../core/analytics/statistics.dart';
import '../../../core/config/territory_config.dart';
import '../../../core/domain/indicator.dart';
import '../../../core/domain/sector.dart';
import '../../../core/domain/territory_area.dart';
import '../../../core/domain/time_series.dart';
import '../../../core/utils/formatters.dart';
import '../../climate/domain/climate_snapshot.dart';
import '../../indicators/domain/indicator_builder.dart';
import '../../indicators/domain/indicator_ids.dart';
import '../../occurrences/domain/occurrence.dart';
import '../../territory_data/data/synthetic_territory_api.dart';
import '../../territory_data/domain/territory_dataset.dart';
import 'alert_thresholds.dart';
import 'territory_alert.dart';

class AlertInputs {
  const AlertInputs({
    required this.today,
    required this.thresholds,
    this.climate,
    this.dataset,
    this.indicators = const {},
    this.occurrences = const [],
  });

  final DateTime today;
  final AlertThresholds thresholds;
  final ClimateSnapshot? climate;
  final TerritoryDataset? dataset;

  /// Indicadores já calculados, por id.
  final Map<String, Indicator> indicators;
  final List<Occurrence> occurrences;
}

class AlertReport {
  const AlertReport({required this.alerts, required this.notes});

  final List<TerritoryAlert> alerts;

  /// Avisos sobre o que não pôde ser avaliado (ex.: clima sem conexão).
  final List<String> notes;
}

/// Gera os alertas a partir dos dados. Funções puras: mesmo dado, mesmo
/// resultado. Nenhum alerta dispara ação automática.
abstract final class AlertEngine {
  static const _synthetic =
      'Baseado em dados sintéticos gerados para fins acadêmicos: o alerta '
      'demonstra o método, não descreve a situação real do território.';

  static AlertReport evaluate(AlertInputs input) {
    final alerts = <TerritoryAlert>[];
    final notes = <String>[];
    final climate = input.climate;
    final dataset = input.dataset;

    if (climate != null) {
      alerts.addAll([
        ?_heatWave(input, climate),
        ?_heavyRain(input, climate),
        ?_airQuality(input, climate),
      ]);
    } else {
      notes.add(
        'Clima indisponível (sem conexão e sem dados salvos): os alertas de '
        'calor, chuva e qualidade do ar não foram avaliados.',
      );
    }

    if (dataset != null) {
      alerts.addAll([
        ?_waterDemand(input, dataset),
        ..._waterLoss(input, dataset),
        ?_energyAnomaly(input, dataset),
        ..._healthDemand(input, dataset),
        ..._wasteRequests(input, dataset),
      ]);
    } else {
      notes.add(
        'Dados de recursos e serviços indisponíveis: os alertas dessas '
        'áreas não foram avaliados.',
      );
    }

    alerts.addAll(_citizenReports(input));
    alerts.sort((a, b) {
      final bySeverity = b.severity.index.compareTo(a.severity.index);
      return bySeverity != 0
          ? bySeverity
          : b.confidence.compareTo(a.confidence);
    });
    return AlertReport(alerts: alerts, notes: notes);
  }

  // ---------------------------------------------------------------- clima

  static TerritoryAlert? _heatWave(AlertInputs input, ClimateSnapshot climate) {
    final limit = input.thresholds[ThresholdField.heatTemperature];
    final minDays = input.thresholds[ThresholdField.heatDays].round();
    final forecast = _forecast(climate, input.today);

    var best = <DailyWeather>[];
    var current = <DailyWeather>[];
    for (final day in forecast) {
      if (day.tempMax >= limit) {
        current = [...current, day];
        if (current.length > best.length) best = current;
      } else {
        current = [];
      }
    }
    final extreme = forecast.where((d) => d.tempMax >= limit + 3).toList();
    if (best.length < minDays && extreme.isEmpty) return null;

    final run = best.length >= minDays ? best : [extreme.first];
    final peak = run.map((d) => d.tempMax).reduce(math.max);
    final ahead = daysBetween(input.today, run.first.date);
    final stale = _staleness(climate, input.today);
    final pastMax = _past(climate, input.today).map((d) => d.tempMax);
    final reports = _reports(input, const [OccurrenceType.heat], _allSectors);

    return TerritoryAlert(
      id: 'calor-territorio',
      kind: AlertKind.heatWave,
      area: TerritoryArea.clima,
      severity: peak >= limit + 3 || run.length >= minDays + 2
          ? AlertSeverity.high
          : AlertSeverity.medium,
      title: run.length > 1
          ? 'Onda de calor prevista por ${run.length} dias'
          : 'Calor extremo previsto ${Fmt.relativeDay(run.first.date, input.today)}',
      summary:
          'A máxima deve chegar a ${_n(peak, 1)} °C a partir de '
          '${Fmt.weekdayDay(run.first.date)}. Idosos, crianças e pessoas com '
          'doenças crônicas são os mais afetados.',
      evidence: [
        for (final day in run)
          '${_cap(Fmt.weekdayDay(day.date))}: máxima prevista de '
              '${_n(day.tempMax, 1)} °C.',
        'Limiar configurado: ${_n(limit, 1)} °C por $minDays '
            '${minDays == 1 ? 'dia' : 'dias seguidos'}.',
        if (pastMax.isNotEmpty)
          'Média das máximas nos últimos 30 dias: '
              '${_n(mean(pastMax.toList().reversed.take(30)), 1)} °C.',
        ?_reportsLine(reports, 'calor extremo'),
      ],
      confidence: clampDouble(0.92 - 0.07 * ahead, 0.35, 0.92) * stale.factor,
      confidenceReason:
          'Previsões de temperatura costumam errar pouco nos primeiros dias '
          'e perdem precisão a cada dia de antecedência.',
      limitations: [
        'Modelo com resolução de alguns quilômetros: não capta ilhas de '
            'calor de ruas sem árvores e áreas muito adensadas.',
        'Não considera a umidade, que muda a sensação térmica.',
        ?_horizonLimitation(ahead),
        ?stale.limitation,
      ],
      suggestedAction:
          'Avaliar abertura de pontos de hidratação e acolhimento, aviso '
          'às UBS sobre atendimento a idosos e reforço na distribuição de água.',
      sectorIds: _allSectors,
      indicatorId: IndicatorIds.temperature,
      expectedDate: run.first.date,
      benefit:
          '${Fmt.compact(TerritoryConfig.totalPopulation)} moradores podem '
          'se preparar com ${_daysAhead(ahead)} de antecedência.',
    );
  }

  static TerritoryAlert? _heavyRain(
    AlertInputs input,
    ClimateSnapshot climate,
  ) {
    final limit = input.thresholds[ThresholdField.rainMm];
    final forecast = _forecast(climate, input.today);
    if (forecast.isEmpty) return null;

    final heavy = forecast.where((d) => d.precipitation >= limit).toList();
    var best72 = 0.0;
    var start72 = 0;
    for (var i = 0; i + 2 < forecast.length; i++) {
      final sum = forecast
          .sublist(i, i + 3)
          .fold(0.0, (total, d) => total + d.precipitation);
      if (sum > best72) {
        best72 = sum;
        start72 = i;
      }
    }
    final accumulated = best72 >= 2 * limit;
    if (heavy.isEmpty && !accumulated) return null;

    final peakDay = heavy.isNotEmpty
        ? heavy.reduce((a, b) => a.precipitation >= b.precipitation ? a : b)
        : forecast[start72];
    final probability = peakDay.precipitationProbability ?? 60;
    final ahead = daysBetween(input.today, peakDay.date);
    final stale = _staleness(climate, input.today);
    final reports = _reports(input, const [
      OccurrenceType.flooding,
    ], _allSectors);

    return TerritoryAlert(
      id: 'chuva-territorio',
      kind: AlertKind.heavyRain,
      area: TerritoryArea.clima,
      severity: peakDay.precipitation >= 2 * limit || best72 >= 3 * limit
          ? AlertSeverity.high
          : AlertSeverity.medium,
      title:
          'Chuva forte prevista ${Fmt.relativeDay(peakDay.date, input.today)}',
      summary:
          'Volume de chuva com risco de alagamentos e deslizamentos em áreas '
          'de encosta e na margem da Guarapiranga.',
      evidence: [
        for (final day in heavy)
          '${_cap(Fmt.weekdayDay(day.date))}: ${_n(day.precipitation, 1)} mm '
              'previstos (probabilidade de chuva de '
              '${_n(day.precipitationProbability ?? 0)}%).',
        if (accumulated)
          'Acumulado de ${_n(best72, 1)} mm em 3 dias a partir de '
              '${Fmt.weekdayDay(forecast[start72].date)}.',
        'Limiar configurado: ${_n(limit)} mm em um dia '
            '(ou o dobro em 3 dias).',
        ?_reportsLine(reports, 'alagamento'),
      ],
      confidence:
          clampDouble(probability / 100 * (0.95 - 0.06 * ahead), 0.3, 0.9) *
          stale.factor,
      confidenceReason:
          'Combina a probabilidade de chuva informada pelo modelo '
          '(${_n(probability)}%) com a antecedência da previsão.',
      limitations: [
        'Chuva de verão é muito localizada: pode cair forte em um bairro e '
            'fraca no vizinho.',
        'O app não tem dados de drenagem nem de áreas de risco mapeadas.',
        ?_horizonLimitation(ahead),
        ?stale.limitation,
      ],
      suggestedAction:
          'Avaliar aviso preventivo da Defesa Civil, limpeza de bocas de '
          'lobo e orientação a moradores de encostas.',
      sectorIds: _allSectors,
      indicatorId: IndicatorIds.rain,
      expectedDate: peakDay.date,
      benefit:
          'Aviso com ${_daysAhead(ahead)} de antecedência para '
          '${Fmt.compact(TerritoryConfig.totalPopulation)} moradores, com '
          'prioridade para quem vive em encostas.',
    );
  }

  static TerritoryAlert? _airQuality(
    AlertInputs input,
    ClimateSnapshot climate,
  ) {
    final limit = input.thresholds[ThresholdField.pm25];
    final bad = _forecast(
      climate,
      input.today,
    ).where((d) => d.pm25 != null && d.pm25! >= limit).toList();
    if (bad.isEmpty) return null;

    final peak = bad.map((d) => d.pm25!).reduce(math.max);
    final ahead = daysBetween(input.today, bad.first.date);
    final stale = _staleness(climate, input.today);
    final pastPm = _past(
      climate,
      input.today,
    ).where((d) => d.pm25 != null).map((d) => d.pm25!).toList();

    return TerritoryAlert(
      id: 'ar-territorio',
      kind: AlertKind.airQuality,
      area: TerritoryArea.clima,
      severity: peak >= 2 * limit ? AlertSeverity.high : AlertSeverity.medium,
      title: 'Ar mais poluído ${Fmt.relativeDay(bad.first.date, input.today)}',
      summary:
          'Partículas finas acima do limiar em ${bad.length} '
          '${bad.length == 1 ? 'dia' : 'dias'}: risco para pessoas com asma, '
          'crianças e idosos.',
      evidence: [
        for (final day in bad)
          '${_cap(Fmt.weekdayDay(day.date))}: média prevista de '
              '${_n(day.pm25!, 1)} µg/m³.',
        'Limiar configurado: ${_n(limit)} µg/m³ (a diretriz da OMS para 24 '
            'horas é 15 µg/m³).',
        if (pastPm.isNotEmpty)
          'Média dos últimos 30 dias: ${_n(mean(pastPm), 1)} µg/m³.',
      ],
      confidence: clampDouble(0.8 - 0.08 * ahead, 0.3, 0.8) * stale.factor,
      confidenceReason:
          'Modelos de qualidade do ar erram mais que os de temperatura, '
          'por isso a confiança máxima é menor.',
      limitations: [
        'Estimativa do modelo CAMS em grade regional, não medição de estação.',
        'Queimadas, obras e trânsito intenso no próprio bairro podem não '
            'aparecer.',
        ?_horizonLimitation(ahead),
        ?stale.limitation,
      ],
      suggestedAction:
          'Avaliar comunicado a grupos sensíveis e preparo das UBS para '
          'mais casos respiratórios.',
      sectorIds: _allSectors,
      indicatorId: IndicatorIds.airQuality,
      expectedDate: bad.first.date,
      benefit:
          'Pessoas com doenças respiratórias podem reduzir a exposição antes '
          'do pico.',
    );
  }

  // ------------------------------------------------------------- recursos

  static TerritoryAlert? _waterDemand(
    AlertInputs input,
    TerritoryDataset data,
  ) {
    final indicator = input.indicators[IndicatorIds.water];
    if (indicator == null || indicator.forecast.isEmpty) return null;

    final values = indicator.history.map((p) => p.value).toList();
    final baseline = mean(values.sublist(values.length - 30));
    final limit = input.thresholds[ThresholdField.waterIncrease] / 100;
    final peak = indicator.forecast.reduce(
      (a, b) => a.value >= b.value ? a : b,
    );
    final increase = peak.value / baseline - 1;
    if (increase < limit) return null;

    final ahead = daysBetween(input.today, peak.date);
    final r2 = indicator.model.r2 ?? 0.5;
    final reports = _reports(input, const [
      OccurrenceType.waterShortage,
    ], _allSectors);

    return TerritoryAlert(
      id: 'agua-consumo-territorio',
      kind: AlertKind.waterDemand,
      area: TerritoryArea.recursos,
      severity: increase >= 1.5 * limit
          ? AlertSeverity.high
          : AlertSeverity.medium,
      title: 'Consumo de água deve subir ${Fmt.percent(increase)}',
      summary:
          'O calor previsto deve elevar o consumo e pressionar o '
          'abastecimento nos horários de pico.',
      evidence: [
        'Consumo previsto de ${_n(peak.value)} L/hab/dia em '
            '${Fmt.weekdayDay(peak.date)}: ${Fmt.percent(increase)} acima '
            'da média de 30 dias (${_n(baseline)}).',
        'Temperatura máxima esperada no dia: '
            '${_n(data.tempMaxOn(peak.date), 1)} °C.',
        _modelLine(indicator.model),
        'Limiar configurado: +${_n(limit * 100)}%.',
        ?_reportsLine(reports, 'falta d’água'),
      ],
      confidence: clampDouble(
        r2 * (1 - 0.05 * ahead) * (data.tempMaxIsReal ? 1 : 0.7),
        0.3,
        0.9,
      ),
      confidenceReason:
          'Vem do R² do modelo (quanto ele explica do histórico), reduzido '
          'pela antecedência'
          '${data.tempMaxIsReal ? '' : ' e pela falta de previsão real de temperatura'}.',
      limitations: [
        _synthetic,
        'Depende da previsão de temperatura: se ela errar, o consumo '
            'previsto erra junto.',
        'Não considera interrupções programadas de abastecimento.',
        ?_horizonLimitation(ahead),
      ],
      suggestedAction:
          'Avaliar campanha de uso consciente e manobras de reforço de '
          'pressão nas partes altas dos bairros.',
      sectorIds: _allSectors,
      indicatorId: IndicatorIds.water,
      expectedDate: peak.date,
      benefit:
          'Reduz o risco de falta d’água no pico de consumo para até '
          '${Fmt.compact(TerritoryConfig.totalPopulation)} moradores.',
    );
  }

  static List<TerritoryAlert> _waterLoss(
    AlertInputs input,
    TerritoryDataset data,
  ) {
    final limit = input.thresholds[ThresholdField.waterLoss];
    final alerts = <TerritoryAlert>[];

    for (final sector in TerritoryConfig.sectors) {
      final values = data.series[SeriesId.waterLoss]![sector.id]!;
      final last7 = values.sublist(values.length - 7);
      final base = values.sublist(0, values.length - 7);
      final recent = mean(last7);
      final baseline = mean(base);
      final z = (recent - baseline) / math.max(standardDeviation(base), 0.3);
      if (z < 3 && recent < limit) continue;

      final slope = linearSlope(values.sublist(values.length - 12));
      final reports = _reports(
        input,
        const [OccurrenceType.leak, OccurrenceType.waterShortage],
        [sector.id],
      );

      // Benefício: volume que voltaria ao normal se o problema for corrigido.
      final perCapita = mean(
        data.series[SeriesId.water]![sector.id]!.reversed.take(7),
      );
      final consumedM3 = sector.population * perCapita / 1000;
      final producedM3 = consumedM3 / (1 - recent / 100);
      final recoverableLiters =
          math.max(0.0, producedM3 * (recent - baseline) / 100) * 1000;

      alerts.add(
        TerritoryAlert(
          id: 'agua-perdas-${sector.id}',
          kind: AlertKind.waterLoss,
          area: TerritoryArea.recursos,
          severity: recent >= limit && z >= 3
              ? AlertSeverity.high
              : AlertSeverity.medium,
          title: 'Perdas de água fora do normal em ${sector.name}',
          summary:
              'As perdas subiram para ${_n(recent, 1)}% e seguem em alta. O '
              'padrão é compatível com um vazamento que ninguém vê.',
          evidence: [
            'Média dos últimos 7 dias: ${_n(recent, 1)}% (histórico do setor: '
                '${_n(baseline, 1)}%).',
            'Desvio de z = ${_n(z, 1)} em relação ao histórico (acima de 3 '
                'indica anomalia).',
            'Tendência: ${slope >= 0 ? '+' : ''}${_n(slope, 2)} ponto '
                'percentual por dia nos últimos 12 dias.',
            'Limiar configurado: ${_n(limit)}%.',
            ?_reportsLine(reports, 'vazamento ou falta d’água'),
          ],
          confidence: math.min(
            0.95,
            clampDouble(0.45 + 0.07 * z, 0.4, 0.92) + (reports > 0 ? 0.05 : 0),
          ),
          confidenceReason:
              'Quanto maior o desvio (z) em relação ao próprio histórico do '
              'setor, menor a chance de ser só variação normal.',
          limitations: [
            _synthetic,
            'Perda aparente mistura vazamento, ligação irregular e erro de '
                'medição.',
            'Indica o setor, não o ponto exato do problema.',
          ],
          suggestedAction:
              'Avaliar pesquisa de vazamentos não visíveis (geofonamento) e '
              'conferência dos medidores do setor.',
          sectorIds: [sector.id],
          indicatorId: IndicatorIds.waterLoss,
          expectedDate: dateOnly(input.today),
          benefit:
              'Se confirmado e corrigido, cerca de '
              '${Fmt.compact(recoverableLiters)} litros/dia deixam de ser '
              'perdidos: o consumo diário de '
              '${Fmt.compact(recoverableLiters / perCapita)} pessoas.',
        ),
      );
    }
    return alerts;
  }

  static TerritoryAlert? _energyAnomaly(
    AlertInputs input,
    TerritoryDataset data,
  ) {
    final history = data.total(SeriesId.energy);
    if (history.length < 40) return null;
    List<double> features(DataPoint p) => [
      1,
      data.tempMaxOn(p.date),
      isWeekend(p.date) ? 1 : 0,
    ];
    final train = history.sublist(history.length - 33, history.length - 3);
    final model = LinearRegression.fit(
      train.map(features).toList(),
      train.map((p) => p.value).toList(),
    );
    final recent = history.sublist(history.length - 3);
    final residual = mean(
      recent.map((p) => p.value - model.predict(features(p))),
    );
    final z = residual / math.max(model.residualStd, 1e-6);
    if (z < 3) return null;

    final expected = mean(recent.map((p) => model.predict(features(p))));
    return TerritoryAlert(
      id: 'energia-territorio',
      kind: AlertKind.energyAnomaly,
      area: TerritoryArea.recursos,
      severity: AlertSeverity.medium,
      title: 'Consumo de energia acima do esperado',
      summary:
          'Nos últimos 3 dias o consumo ficou acima do que o calor e o dia '
          'da semana explicam.',
      evidence: [
        'Média dos últimos 3 dias: ${_n(mean(recent.map((p) => p.value)))} '
            'MWh/dia; esperado pelo modelo: ${_n(expected)} MWh/dia.',
        'Desvio de z = ${_n(z, 1)} em relação ao erro típico do modelo.',
      ],
      confidence: clampDouble(0.4 + 0.08 * z, 0.4, 0.85),
      confidenceReason:
          'Proporcional ao tamanho do desvio em relação ao erro típico.',
      limitations: [
        _synthetic,
        'Eventos (feriados, jogos, falhas de medição) também explicam picos.',
      ],
      suggestedAction:
          'Avaliar com a distribuidora se há sobrecarga ou falha de medição.',
      sectorIds: _allSectors,
      indicatorId: IndicatorIds.energy,
      expectedDate: dateOnly(input.today),
    );
  }

  // ------------------------------------------------------------- serviços

  static List<TerritoryAlert> _healthDemand(
    AlertInputs input,
    TerritoryDataset data,
  ) {
    final limit = input.thresholds[ThresholdField.healthOccupancy] / 100;
    final future = [
      for (var i = 0; i < SyntheticTerritoryApi.forecastDays; i++)
        addDays(input.today, i),
    ];
    final alerts = <TerritoryAlert>[];

    for (final sector in TerritoryConfig.sectors) {
      final history = data.sectorSeries(SeriesId.health, sector.id);
      final forecast = IndicatorBuilder.healthForecastFor(history, future);
      final peak = forecast.points.reduce((a, b) => a.value >= b.value ? a : b);
      final occupancy = peak.value / sector.healthDailyCapacity;
      if (occupancy < limit) continue;

      final weekdays = [
        for (final p in history)
          if (!isWeekend(p.date)) p.value,
      ];
      final recentWeekdays = weekdays.sublist(weekdays.length - 20);
      final slope = linearSlope(recentWeekdays);
      final ahead = daysBetween(input.today, peak.date);

      alerts.add(
        TerritoryAlert(
          id: 'ubs-demanda-${sector.id}',
          kind: AlertKind.healthDemand,
          area: TerritoryArea.servicos,
          severity: occupancy >= 1 ? AlertSeverity.high : AlertSeverity.medium,
          title: 'UBS de ${sector.name} perto do limite',
          summary:
              'A demanda vem subindo e pode chegar a '
              '${Fmt.percent(occupancy)} da capacidade de atendimento.',
          evidence: [
            'Previsão de ${_n(peak.value)} atendimentos em '
                '${Fmt.weekdayDay(peak.date)}: ${Fmt.percent(occupancy)} da '
                'capacidade diária (${sector.healthDailyCapacity}).',
            'Média dos últimos 20 dias úteis: ${_n(mean(recentWeekdays))} '
                'atendimentos.',
            'Tendência: ${slope >= 0 ? '+' : ''}${_n(slope, 1)} atendimentos '
                'a cada dia útil.',
            _modelLine(forecast.model),
            'Limiar configurado: ${_n(limit * 100)}% da capacidade.',
          ],
          confidence: clampDouble(
            (forecast.model.r2 ?? 0.5) * (1 - 0.05 * ahead),
            0.3,
            0.9,
          ),
          confidenceReason:
              'Vem do R² do modelo de tendência, reduzido pela antecedência.',
          limitations: [
            _synthetic,
            'Capacidade diária estimada; não considera faltas de profissionais.',
            'Surtos (dengue, gripe) podem acelerar a demanda além da '
                'tendência linear.',
            ?_horizonLimitation(ahead),
          ],
          suggestedAction:
              'Avaliar remanejamento de equipe, horário estendido ou mutirão '
              'de agendamento. Não substitui a triagem clínica.',
          sectorIds: [sector.id],
          indicatorId: IndicatorIds.health,
          expectedDate: peak.date,
          benefit:
              '${Fmt.compact(sector.population)} moradores dependem dessas '
              'UBS: agir antes reduz filas e tempo de espera.',
        ),
      );
    }
    return alerts;
  }

  static List<TerritoryAlert> _wasteRequests(
    AlertInputs input,
    TerritoryDataset data,
  ) {
    final limit = input.thresholds[ThresholdField.wasteIncrease] / 100;
    final rainLimit = input.thresholds[ThresholdField.rainMm];
    final climate = input.climate;
    final rainSoon =
        climate != null &&
        _forecast(
          climate,
          input.today,
        ).any((d) => d.precipitation >= 0.7 * rainLimit);
    final alerts = <TerritoryAlert>[];

    for (final sector in TerritoryConfig.sectors) {
      final values = data.series[SeriesId.waste]![sector.id]!;
      final recent = mean(values.sublist(values.length - 7));
      final previous = mean(
        values.sublist(values.length - 37, values.length - 7),
      );
      if (previous <= 0) continue;
      final increase = recent / previous - 1;
      if (increase < limit) continue;

      final reports = _reports(
        input,
        const [OccurrenceType.garbage, OccurrenceType.flooding],
        [sector.id],
      );

      alerts.add(
        TerritoryAlert(
          id: 'coleta-${sector.id}',
          kind: AlertKind.wasteRequests,
          area: TerritoryArea.servicos,
          severity: rainSoon || increase >= 2 * limit
              ? AlertSeverity.high
              : AlertSeverity.medium,
          title: 'Mais lixo acumulado em ${sector.name}',
          summary:
              'As solicitações de coleta subiram ${Fmt.percent(increase)}'
              '${rainSoon ? ' e há chuva forte prevista' : ''}.',
          evidence: [
            'Média de ${_n(recent, 1)} solicitações/dia nos últimos 7 dias, '
                'contra ${_n(previous, 1)} nos 30 dias anteriores '
                '(+${Fmt.percent(increase)}).',
            if (rainSoon)
              'Há chuva forte prevista: lixo nas ruas pode entupir bueiros e '
                  'agravar alagamentos.',
            'Limiar configurado: +${_n(limit * 100)}%.',
            ?_reportsLine(reports, 'lixo ou alagamento'),
          ],
          confidence: math.min(
            0.9,
            clampDouble(0.45 + 0.5 * (increase - limit), 0.4, 0.85) +
                (reports > 0 ? 0.05 : 0),
          ),
          confidenceReason:
              'Quanto maior o aumento acima do limiar, maior a confiança; '
              'relatos de cidadãos no setor reforçam o sinal.',
          limitations: [
            _synthetic,
            'Viés de notificação: bairros que reclamam menos parecem estar '
                'melhor do que estão.',
            'Mais solicitações podem refletir uma campanha de divulgação, e '
                'não mais lixo.',
          ],
          suggestedAction:
              'Avaliar mutirão de coleta, fiscalização de pontos de descarte '
              'irregular e limpeza de bocas de lobo.',
          sectorIds: [sector.id],
          indicatorId: IndicatorIds.waste,
          expectedDate: dateOnly(input.today),
          benefit:
              'Reduz o risco de alagamentos e de doenças transmitidas por '
              'ratos e mosquitos para ${Fmt.compact(sector.population)} '
              'moradores.',
        ),
      );
    }
    return alerts;
  }

  // ------------------------------------------------------------ cidadãos

  static List<TerritoryAlert> _citizenReports(AlertInputs input) {
    final since = addDays(input.today, -2);
    final groups = <String, List<Occurrence>>{};
    for (final occurrence in input.occurrences) {
      if (occurrence.type == OccurrenceType.other) continue;
      if (occurrence.occurredOn.isBefore(since)) continue;
      groups
          .putIfAbsent(
            '${occurrence.type.name}|${occurrence.sectorId}',
            () => [],
          )
          .add(occurrence);
    }

    final alerts = <TerritoryAlert>[];
    for (final group in groups.values) {
      if (group.length < 2) continue;
      final type = group.first.type;
      final sector = TerritoryConfig.sectorById(group.first.sectorId);
      final serious = group.where((o) => o.severity == OccurrenceSeverity.high);
      final (area, indicatorId) = _citizenTarget(type);

      alerts.add(
        TerritoryAlert(
          id: 'relatos-${type.name}-${sector.id}',
          kind: AlertKind.citizenReports,
          area: area,
          severity: group.length >= 3 || serious.isNotEmpty
              ? AlertSeverity.medium
              : AlertSeverity.low,
          title: 'Relatos de ${type.label.toLowerCase()} em ${sector.name}',
          summary:
              '${group.length} moradores relataram o mesmo problema no setor '
              'nos últimos 3 dias.',
          evidence: [
            '${group.length} relatos anônimos de '
                '${type.label.toLowerCase()} nos últimos 3 dias.',
            'Gravidade informada: '
                '${OccurrenceSeverity.values.map((s) => '${group.where((o) => o.severity == s).length} ${s.label.toLowerCase()}').join(', ')}.',
          ],
          confidence: group.length >= 3 ? 0.5 : 0.4,
          confidenceReason:
              'Relatos são sinais úteis, mas não verificados: a confiança '
              'fica baixa até uma vistoria confirmar.',
          limitations: const [
            'Relatos não verificados: podem ser duplicados ou imprecisos.',
            'Poucos relatos não indicam o tamanho do problema.',
          ],
          suggestedAction:
              'Avaliar vistoria no local para confirmar os relatos.',
          sectorIds: [sector.id],
          indicatorId: indicatorId,
          expectedDate: dateOnly(input.today),
          benefit:
              'Dá voz aos moradores e acelera a resposta a problemas que os '
              'dados ainda não mostram.',
        ),
      );
    }
    return alerts;
  }

  static (TerritoryArea, String) _citizenTarget(OccurrenceType type) =>
      switch (type) {
        OccurrenceType.flooding => (TerritoryArea.clima, IndicatorIds.rain),
        OccurrenceType.heat => (TerritoryArea.clima, IndicatorIds.temperature),
        OccurrenceType.waterShortage => (
          TerritoryArea.recursos,
          IndicatorIds.water,
        ),
        OccurrenceType.leak => (TerritoryArea.recursos, IndicatorIds.waterLoss),
        OccurrenceType.garbage ||
        OccurrenceType.other => (TerritoryArea.servicos, IndicatorIds.waste),
      };

  // ------------------------------------------------------------- apoio

  static final List<String> _allSectors = [
    for (final Sector sector in TerritoryConfig.sectors) sector.id,
  ];

  static List<DailyWeather> _forecast(ClimateSnapshot climate, DateTime today) {
    final day0 = dateOnly(today);
    return climate.days.where((d) => !d.date.isBefore(day0)).toList();
  }

  static List<DailyWeather> _past(ClimateSnapshot climate, DateTime today) {
    final day0 = dateOnly(today);
    return climate.days.where((d) => d.date.isBefore(day0)).toList();
  }

  static ({double factor, String? limitation}) _staleness(
    ClimateSnapshot climate,
    DateTime today,
  ) {
    if (!climate.fromCache) return (factor: 1.0, limitation: null);
    return (
      factor: 0.85,
      limitation:
          'Sem conexão: usando dados salvos em '
          '${Fmt.dateTime(climate.fetchedAt)}. A previsão pode estar '
          'desatualizada.',
    );
  }

  static String? _horizonLimitation(int ahead) => ahead >= 3
      ? 'Previsão para daqui a $ahead dias: quanto mais distante, maior a '
            'incerteza.'
      : null;

  static int _reports(
    AlertInputs input,
    List<OccurrenceType> types,
    List<String> sectorIds,
  ) {
    final since = addDays(input.today, -7);
    return input.occurrences
        .where(
          (o) =>
              types.contains(o.type) &&
              sectorIds.contains(o.sectorId) &&
              !o.occurredOn.isBefore(since),
        )
        .length;
  }

  static String? _reportsLine(int count, String subject) => count == 0
      ? null
      : '$count ${count == 1 ? 'relato' : 'relatos'} de cidadãos sobre '
            '$subject nos últimos 7 dias.';

  static String _modelLine(ModelInfo model) {
    final parts = [
      if (model.r2 != null) 'R² = ${_n(model.r2!, 2)}',
      if (model.mape != null)
        'erro médio de ${Fmt.percent(model.mape!, decimals: 1)} no backtest',
    ];
    return 'Modelo: ${model.name}${parts.isEmpty ? '' : ' (${parts.join('; ')})'}.';
  }

  static String _daysAhead(int ahead) =>
      ahead <= 0 ? 'algumas horas' : '$ahead ${ahead == 1 ? 'dia' : 'dias'}';

  static String _n(num value, [int decimals = 0]) =>
      Fmt.number(value, decimals: decimals);

  static String _cap(String text) =>
      text.isEmpty ? text : text[0].toUpperCase() + text.substring(1);
}
