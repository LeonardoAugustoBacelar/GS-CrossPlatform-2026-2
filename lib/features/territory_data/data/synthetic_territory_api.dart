import 'dart:math' as math;

import '../../../core/config/territory_config.dart';
import '../../../core/domain/time_series.dart';

/// Simula o serviço de dados da subprefeitura e das concessionárias.
///
/// Gera **dados sintéticos** diários por setor, de forma determinística: a
/// mesma data produz sempre os mesmos números. Os valores seguem padrões
/// plausíveis (sazonalidade semanal, efeito do calor no consumo) e incluem
/// três situações anômalas plantadas de propósito para exercitar os alertas:
///
/// - vazamento crescente no setor Jardim Ângela Sul (perdas de água);
/// - aumento de demanda nas UBS do Jardim Ângela Norte;
/// - alta de solicitações de coleta no Jardim São Luís Leste.
///
/// Quando há clima real, a temperatura máxima observada/prevista é usada como
/// fator de consumo de água e energia; sem ela, usa-se uma climatologia.
class SyntheticTerritoryApi {
  SyntheticTerritoryApi({
    required DateTime today,
    this.realTempMax = const {},
    this.latency = const Duration(milliseconds: 600),
  }) : today = dateOnly(today);

  final DateTime today;

  /// Temperatura máxima real por dia (`aaaa-mm-dd`), quando disponível.
  final Map<String, double> realTempMax;
  final Duration latency;

  static const historyDays = 60;
  static const forecastDays = 7;
  static const sourceName = 'API simulada Mirante (dados sintéticos)';

  Future<Map<String, dynamic>> fetchDailySeries() async {
    if (latency > Duration.zero) await Future<void>.delayed(latency);
    return generate();
  }

  Map<String, dynamic> generate() {
    final dates = [for (var i = historyDays; i >= 1; i--) addDays(today, -i)];
    final drivers = <String, double>{
      for (var i = -historyDays; i < forecastDays; i++)
        dateKey(addDays(today, i)): _tempMax(addDays(today, i)),
    };

    final series = <String, Map<String, List<double>>>{
      for (final id in SeriesId.all) id: {},
    };

    for (final sector in TerritoryConfig.sectors) {
      final water = <double>[];
      final loss = <double>[];
      final energy = <double>[];
      final health = <double>[];
      final waste = <double>[];

      for (final date in dates) {
        final key = dateKey(date);
        final daysAgo = daysBetween(date, today);
        final heat = drivers[key]! - 25;
        final weekend = isWeekend(date);
        double noise(String serie) => _gaussian('$serie|${sector.id}|$key');

        // Consumo de água por habitante (L/hab/dia).
        final waterBase = _waterBase[sector.id]!;
        water.add(
          waterBase * (1 + 0.017 * heat) * (weekend ? 1.05 : 1) +
              2.5 * noise('agua'),
        );

        // Perdas na distribuição (%), com vazamento plantado no Jardim Ângela Sul.
        final leak = sector.id == 'ja-sul' ? 8.5 * _ramp(daysAgo, 12) : 0.0;
        loss.add(_lossBase[sector.id]! + leak + 0.8 * noise('perdas'));

        // Energia elétrica residencial (MWh/dia).
        energy.add(
          sector.population *
              2.1 /
              1000 *
              (1 + 0.022 * heat) *
              (weekend ? 0.93 : 1) *
              (1 + 0.015 * noise('energia')),
        );

        // Atendimentos nas UBS, com alta plantada no Jardim Ângela Norte.
        final surge = sector.id == 'ja-norte' ? 0.32 * _ramp(daysAgo, 21) : 0.0;
        health.add(
          (sector.healthDailyCapacity *
                  _healthLoad[sector.id]! *
                  _weekdayDemand[date.weekday]! *
                  (1 + surge) *
                  (1 + 0.04 * noise('ubs')))
              .roundToDouble(),
        );

        // Solicitações de coleta e descarte irregular, com alta no JSL Leste.
        final wasteRise = sector.id == 'jsl-leste'
            ? 1.0 * _ramp(daysAgo, 12)
            : 0.0;
        final lambda =
            sector.population / 12000 * (weekend ? 0.7 : 1) * (1 + wasteRise);
        waste.add(
          math
              .max(0, lambda + math.sqrt(lambda) * noise('coleta'))
              .roundToDouble(),
        );
      }

      series[SeriesId.water]![sector.id] = water;
      series[SeriesId.waterLoss]![sector.id] = loss;
      series[SeriesId.energy]![sector.id] = energy;
      series[SeriesId.health]![sector.id] = health;
      series[SeriesId.waste]![sector.id] = waste;
    }

    return {
      'source': sourceName,
      'generatedAt': today.toIso8601String(),
      'dates': [for (final date in dates) dateKey(date)],
      'tempMax': drivers,
      'tempMaxIsReal': realTempMax.isNotEmpty,
      'series': series,
    };
  }

  double _tempMax(DateTime date) {
    final real = realTempMax[dateKey(date)];
    if (real != null) return real;
    // Climatologia aproximada de São Paulo: mais quente em fevereiro.
    final dayOfYear = daysBetween(DateTime(date.year), date);
    return 25.5 +
        3.5 * math.cos(2 * math.pi * (dayOfYear - 40) / 365.25) +
        1.8 * _gaussian('clima|${dateKey(date)}');
  }

  /// 1 no dia mais recente, caindo até 0 em [length] dias atrás.
  static double _ramp(int daysAgo, int length) =>
      daysAgo >= length ? 0 : (length - daysAgo) / length;

  /// Ruído normal padrão determinístico a partir de uma chave de texto.
  static double _gaussian(String key) {
    var hash = 0x811c9dc5;
    for (final unit in key.codeUnits) {
      hash = ((hash ^ unit) * 0x01000193) & 0xFFFFFFFF;
    }
    double next() {
      hash ^= (hash << 13) & 0xFFFFFFFF;
      hash ^= hash >> 17;
      hash ^= (hash << 5) & 0xFFFFFFFF;
      hash &= 0xFFFFFFFF;
      return (hash + 1) / 4294967297.0;
    }

    final u1 = next();
    final u2 = next();
    return math.sqrt(-2 * math.log(u1)) * math.cos(2 * math.pi * u2);
  }

  static const _waterBase = {
    'ja-norte': 148.0,
    'ja-sul': 141.0,
    'jsl-oeste': 156.0,
    'jsl-leste': 162.0,
  };

  static const _lossBase = {
    'ja-norte': 30.5,
    'ja-sul': 31.2,
    'jsl-oeste': 29.4,
    'jsl-leste': 32.1,
  };

  static const _healthLoad = {
    'ja-norte': 0.78,
    'ja-sul': 0.71,
    'jsl-oeste': 0.69,
    'jsl-leste': 0.73,
  };

  static const _weekdayDemand = {
    DateTime.monday: 1.08,
    DateTime.tuesday: 1.0,
    DateTime.wednesday: 0.98,
    DateTime.thursday: 0.97,
    DateTime.friday: 0.93,
    DateTime.saturday: 0.45,
    DateTime.sunday: 0.25,
  };
}

/// Identificadores das séries entregues pela API simulada.
abstract final class SeriesId {
  static const water = 'agua_litros_hab_dia';
  static const waterLoss = 'perdas_pct';
  static const energy = 'energia_mwh';
  static const health = 'ubs_atendimentos';
  static const waste = 'coleta_solicitacoes';

  static const all = [water, waterLoss, energy, health, waste];
}
