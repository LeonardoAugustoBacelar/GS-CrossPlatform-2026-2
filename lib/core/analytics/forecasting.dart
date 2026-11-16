import 'dart:math' as math;

import '../domain/indicator.dart';
import '../domain/time_series.dart';
import 'linear_regression.dart';
import 'statistics.dart';

/// Monta as variáveis explicativas de um dia. [index] é a posição do dia na
/// série (0 = primeiro dia do histórico usado no ajuste).
typedef FeatureBuilder = List<double> Function(DateTime date, int index);

class ForecastResult {
  const ForecastResult({required this.points, required this.model});

  final List<ForecastPoint> points;
  final ModelInfo model;
}

/// Ajusta uma regressão linear no histórico e projeta as datas futuras, com
/// intervalo de 90% que se abre conforme a previsão se afasta de hoje.
///
/// A qualidade é medida por backtest: o modelo é ajustado sem os últimos
/// [backtestDays] dias e o erro (MAPE) é calculado sobre eles.
ForecastResult regressionForecast({
  required List<DataPoint> history,
  required List<DateTime> futureDates,
  required FeatureBuilder features,
  required String modelName,
  required String modelDescription,
  int backtestDays = 14,
}) {
  final rows = [
    for (var i = 0; i < history.length; i++) features(history[i].date, i),
  ];
  final target = [for (final point in history) point.value];
  final model = LinearRegression.fit(rows, target);

  double? mape;
  final trainSize = history.length - backtestDays;
  if (trainSize > rows.first.length + 5) {
    final backtest = LinearRegression.fit(
      rows.sublist(0, trainSize),
      target.sublist(0, trainSize),
    );
    final predicted = [
      for (var i = trainSize; i < history.length; i++)
        backtest.predict(rows[i]),
    ];
    mape = meanAbsolutePercentageError(target.sublist(trainSize), predicted);
  }

  const z90 = 1.645;
  final points = <ForecastPoint>[];
  for (var h = 0; h < futureDates.length; h++) {
    final value = model.predict(features(futureDates[h], history.length + h));
    final spread = z90 * model.residualStd * math.sqrt(1 + 0.15 * (h + 1));
    points.add(
      ForecastPoint(
        date: futureDates[h],
        value: math.max(0, value),
        lower: math.max(0, value - spread),
        upper: value + spread,
      ),
    );
  }

  return ForecastResult(
    points: points,
    model: ModelInfo(
      name: modelName,
      description: modelDescription,
      r2: model.r2,
      mape: mape?.isNaN ?? true ? null : mape,
      sampleSize: model.sampleSize,
      intervalLabel: 'Faixa sombreada: intervalo de 90%',
    ),
  );
}
