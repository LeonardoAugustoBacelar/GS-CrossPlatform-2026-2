import 'package:flutter_test/flutter_test.dart';
import 'package:mirante/core/analytics/forecasting.dart';
import 'package:mirante/core/analytics/linear_regression.dart';
import 'package:mirante/core/analytics/statistics.dart';
import 'package:mirante/core/domain/time_series.dart';

void main() {
  test('regressão recupera os coeficientes de uma reta exata', () {
    final rows = [
      for (var x = 0; x < 10; x++) [1.0, x.toDouble()],
    ];
    final y = [for (var x = 0; x < 10; x++) 2 + 3.0 * x];
    final model = LinearRegression.fit(rows, y);
    expect(model.coefficients[0], closeTo(2, 1e-6));
    expect(model.coefficients[1], closeTo(3, 1e-6));
    expect(model.r2, closeTo(1, 1e-9));
  });

  test('variável constante na janela não quebra o ajuste', () {
    final rows = [
      for (var x = 0; x < 10; x++) [1.0, x.toDouble(), 0.0],
    ];
    final y = [for (var x = 0; x < 10; x++) 5.0 + x];
    final model = LinearRegression.fit(rows, y);
    expect(model.predict([1, 20, 0]), closeTo(25, 1e-3));
  });

  test('previsão continua a tendência e abre o intervalo com o tempo', () {
    final start = DateTime(2026, 10, 1);
    final history = [
      for (var i = 0; i < 30; i++)
        DataPoint(addDays(start, i), 100 + 2.0 * i + (i.isEven ? 1 : -1)),
    ];
    final result = regressionForecast(
      history: history,
      futureDates: [for (var i = 30; i < 37; i++) addDays(start, i)],
      features: (_, index) => [1, index.toDouble()],
      modelName: 'teste',
      modelDescription: 'teste',
    );
    expect(result.points.first.value, closeTo(160, 2));
    final first = result.points.first;
    final last = result.points.last;
    expect(last.upper - last.lower, greaterThan(first.upper - first.lower));
    expect(result.model.mape, isNotNull);
  });

  test('estatísticas básicas', () {
    expect(mean([1, 2, 3]), 2);
    expect(standardDeviation([2, 4, 4, 4, 5, 5, 7, 9]), closeTo(2.138, 1e-3));
    expect(linearSlope([1, 3, 5, 7]), closeTo(2, 1e-9));
    expect(
      meanAbsolutePercentageError([100, 200], [110, 180]),
      closeTo(0.1, 1e-9),
    );
  });
}
