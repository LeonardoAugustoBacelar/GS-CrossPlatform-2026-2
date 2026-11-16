import 'package:flutter_test/flutter_test.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:mirante/core/domain/indicator.dart';
import 'package:mirante/features/alerts/domain/alert_engine.dart';
import 'package:mirante/features/alerts/domain/alert_thresholds.dart';
import 'package:mirante/features/alerts/domain/territory_alert.dart';
import 'package:mirante/features/climate/domain/climate_snapshot.dart';
import 'package:mirante/features/indicators/domain/indicator_builder.dart';
import 'package:mirante/features/occurrences/domain/occurrence.dart';

import 'support/fixtures.dart';

AlertReport _evaluate({
  ClimateSnapshot? climate,
  bool withDataset = true,
  AlertThresholds thresholds = const AlertThresholds(),
  List<Occurrence> occurrences = const [],
}) {
  final dataset = withDataset ? datasetFixture(climate: climate) : null;
  final indicators = <String, Indicator>{
    if (climate != null)
      for (final i in IndicatorBuilder.climate(climate, today)) i.id: i,
    if (dataset != null) ...{
      for (final i in IndicatorBuilder.resources(dataset, today)) i.id: i,
      for (final i in IndicatorBuilder.services(dataset, today)) i.id: i,
    },
  };
  return AlertEngine.evaluate(
    AlertInputs(
      today: today,
      thresholds: thresholds,
      climate: climate,
      dataset: dataset,
      indicators: indicators,
      occurrences: occurrences,
    ),
  );
}

List<TerritoryAlert> _ofKind(AlertReport report, AlertKind kind) =>
    report.alerts.where((a) => a.kind == kind).toList();

Occurrence _report(OccurrenceType type, String sectorId, int index) =>
    Occurrence(
      id: '$index',
      type: type,
      sectorId: sectorId,
      description: 'Relato de teste número $index',
      severity: OccurrenceSeverity.medium,
      occurredOn: today,
      createdAt: today,
    );

void main() {
  setUpAll(() => initializeDateFormatting('pt_BR'));

  group('onda de calor', () {
    test('dispara com 2 dias seguidos acima do limiar', () {
      final report = _evaluate(
        climate: climateFixture(forecastMax: [30, 33, 34, 31, 29, 28, 27]),
      );
      final heat = _ofKind(report, AlertKind.heatWave).single;
      expect(heat.severity, AlertSeverity.medium);
      expect(
        heat.evidence.where((e) => e.contains('máxima prevista')),
        hasLength(2),
      );
      expect(heat.expectedDate, DateTime(2026, 11, 17));
    });

    test('não dispara quando o limiar configurado é maior', () {
      final report = _evaluate(
        climate: climateFixture(forecastMax: [30, 33, 34, 31, 29, 28, 27]),
        thresholds: const AlertThresholds().copyWith({
          ThresholdField.heatTemperature: 35,
        }),
      );
      expect(_ofKind(report, AlertKind.heatWave), isEmpty);
    });

    test('baixar o limiar gera o alerta (decisão do gestor)', () {
      final climate = climateFixture();
      expect(_ofKind(_evaluate(climate: climate), AlertKind.heatWave), isEmpty);
      final lowered = _evaluate(
        climate: climate,
        thresholds: const AlertThresholds().copyWith({
          ThresholdField.heatTemperature: 27,
        }),
      );
      expect(_ofKind(lowered, AlertKind.heatWave), hasLength(1));
    });

    test('dados do cache reduzem a confiança e entram nas limitações', () {
      final online = _ofKind(
        _evaluate(
          climate: climateFixture(forecastMax: [33, 34, 27, 27, 27, 27, 27]),
        ),
        AlertKind.heatWave,
      ).single;
      final offline = _ofKind(
        _evaluate(
          climate: climateFixture(
            forecastMax: [33, 34, 27, 27, 27, 27, 27],
            fromCache: true,
          ),
        ),
        AlertKind.heatWave,
      ).single;
      expect(offline.confidence, lessThan(online.confidence));
      expect(offline.limitations.any((l) => l.contains('Sem conexão')), isTrue);
    });
  });

  test('chuva forte usa a probabilidade na confiança', () {
    final likely = _ofKind(
      _evaluate(climate: climateFixture(forecastRain: [0, 45, 0, 0, 0, 0, 0])),
      AlertKind.heavyRain,
    ).single;
    final unlikely = _ofKind(
      _evaluate(
        climate: climateFixture(
          forecastRain: [0, 45, 0, 0, 0, 0, 0],
          rainProbability: 40,
        ),
      ),
      AlertKind.heavyRain,
    ).single;
    expect(unlikely.confidence, lessThan(likely.confidence));
  });

  test('qualidade do ar dispara acima do limiar de PM2,5', () {
    final report = _evaluate(
      climate: climateFixture(forecastPm25: [12, 31, 28, 12]),
    );
    expect(_ofKind(report, AlertKind.airQuality), hasLength(1));
  });

  group('dados sintéticos', () {
    test('perdas de água: só o setor com vazamento plantado', () {
      final alerts = _ofKind(
        _evaluate(climate: climateFixture()),
        AlertKind.waterLoss,
      );
      expect(alerts.map((a) => a.sectorIds.single), ['ja-sul']);
      expect(alerts.single.severity, AlertSeverity.high);
      expect(alerts.single.benefit, contains('litros/dia'));
    });

    test('UBS: alerta no setor com demanda crescente', () {
      final alerts = _ofKind(
        _evaluate(climate: climateFixture()),
        AlertKind.healthDemand,
      );
      expect(alerts.map((a) => a.sectorIds.single), contains('ja-norte'));
    });

    test('coleta: alerta no setor com alta de solicitações', () {
      final alerts = _ofKind(
        _evaluate(climate: climateFixture()),
        AlertKind.wasteRequests,
      );
      expect(alerts.map((a) => a.sectorIds.single), contains('jsl-leste'));
    });

    test('os dados são determinísticos para a mesma data', () {
      final a = datasetFixture(climate: climateFixture());
      final b = datasetFixture(climate: climateFixture());
      expect(a.series, equals(b.series));
    });
  });

  test('todo alerta traz evidência, confiança, limitações e ação sugerida', () {
    final report = _evaluate(
      climate: climateFixture(
        forecastMax: [33, 34, 35, 27, 27, 27, 27],
        forecastRain: [0, 50, 20, 0, 0, 0, 0],
        forecastPm25: [30, 30],
      ),
    );
    expect(report.alerts, isNotEmpty);
    for (final alert in report.alerts) {
      expect(alert.evidence, isNotEmpty, reason: alert.id);
      expect(alert.limitations, isNotEmpty, reason: alert.id);
      expect(alert.suggestedAction, isNotEmpty, reason: alert.id);
      expect(alert.confidence, inInclusiveRange(0, 1), reason: alert.id);
    }
    final ids = report.alerts.map((a) => a.id).toList();
    expect(ids.toSet(), hasLength(ids.length), reason: 'ids únicos');
  });

  test('sem clima: avalia o resto e avisa o que ficou de fora', () {
    final report = _evaluate();
    expect(report.notes.single, contains('Clima indisponível'));
    expect(report.alerts.where((a) => a.kind == AlertKind.heatWave), isEmpty);
    expect(_ofKind(report, AlertKind.waterLoss), isNotEmpty);
  });

  group('relatos de cidadãos', () {
    test('dois relatos iguais no mesmo setor geram alerta', () {
      final report = _evaluate(
        withDataset: false,
        occurrences: [
          _report(OccurrenceType.flooding, 'ja-sul', 1),
          _report(OccurrenceType.flooding, 'ja-sul', 2),
        ],
      );
      final alert = _ofKind(report, AlertKind.citizenReports).single;
      expect(alert.confidence, lessThan(0.5));
    });

    test('um relato só não gera alerta', () {
      final report = _evaluate(
        withDataset: false,
        occurrences: [_report(OccurrenceType.flooding, 'ja-sul', 1)],
      );
      expect(_ofKind(report, AlertKind.citizenReports), isEmpty);
    });
  });
}
