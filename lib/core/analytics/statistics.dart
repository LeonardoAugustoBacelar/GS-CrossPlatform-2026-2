import 'dart:math' as math;

double mean(Iterable<double> values) {
  if (values.isEmpty) return double.nan;
  return values.reduce((a, b) => a + b) / values.length;
}

/// Desvio-padrão amostral.
double standardDeviation(Iterable<double> values) {
  if (values.length < 2) return 0;
  final m = mean(values);
  final squares = values.map((v) => (v - m) * (v - m));
  return math.sqrt(squares.reduce((a, b) => a + b) / (values.length - 1));
}

/// Inclinação da reta de mínimos quadrados, em unidades por passo.
double linearSlope(List<double> values) {
  final n = values.length;
  if (n < 2) return 0;
  final xMean = (n - 1) / 2;
  final yMean = mean(values);
  var numerator = 0.0;
  var denominator = 0.0;
  for (var i = 0; i < n; i++) {
    numerator += (i - xMean) * (values[i] - yMean);
    denominator += (i - xMean) * (i - xMean);
  }
  return denominator == 0 ? 0 : numerator / denominator;
}

/// Erro percentual absoluto médio (MAPE), ignorando valores reais zerados.
double meanAbsolutePercentageError(
  List<double> actual,
  List<double> predicted,
) {
  final errors = <double>[
    for (var i = 0; i < actual.length; i++)
      if (actual[i] != 0) ((actual[i] - predicted[i]) / actual[i]).abs(),
  ];
  return errors.isEmpty ? double.nan : mean(errors);
}

double clampDouble(double value, double min, double max) =>
    value < min ? min : (value > max ? max : value);
