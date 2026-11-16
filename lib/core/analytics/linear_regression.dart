import 'dart:math' as math;

import 'statistics.dart';

/// Regressão linear múltipla por mínimos quadrados (equações normais).
///
/// Cada linha de entrada já deve trazer o termo constante (1.0) se desejado.
class LinearRegression {
  const LinearRegression._({
    required this.coefficients,
    required this.r2,
    required this.residualStd,
    required this.sampleSize,
  });

  final List<double> coefficients;

  /// Coeficiente de determinação (0 a 1): quanto da variação o modelo explica.
  final double r2;

  /// Desvio-padrão dos resíduos, usado no intervalo de previsão.
  final double residualStd;
  final int sampleSize;

  static LinearRegression fit(List<List<double>> rows, List<double> target) {
    final n = rows.length;
    if (n == 0 || n != target.length) {
      throw ArgumentError('Linhas e alvo precisam ter o mesmo tamanho.');
    }
    final k = rows.first.length;
    if (n <= k) {
      throw ArgumentError('São necessários mais de $k pontos para o ajuste.');
    }

    final xtx = List.generate(k, (_) => List<double>.filled(k, 0));
    final xty = List<double>.filled(k, 0);
    for (var i = 0; i < n; i++) {
      for (var a = 0; a < k; a++) {
        xty[a] += rows[i][a] * target[i];
        for (var b = 0; b < k; b++) {
          xtx[a][b] += rows[i][a] * rows[i][b];
        }
      }
    }
    // Regularização mínima: evita matriz singular quando uma variável não
    // varia na janela (ex.: nenhum domingo nos dados).
    for (var a = 0; a < k; a++) {
      xtx[a][a] += 1e-9;
    }

    final beta = _solve(xtx, xty);
    final yMean = mean(target);
    var ssTotal = 0.0;
    var ssResidual = 0.0;
    for (var i = 0; i < n; i++) {
      final predicted = _dot(beta, rows[i]);
      ssResidual += math.pow(target[i] - predicted, 2);
      ssTotal += math.pow(target[i] - yMean, 2);
    }
    final r2 = ssTotal == 0 ? 0.0 : 1 - ssResidual / ssTotal;

    return LinearRegression._(
      coefficients: beta,
      r2: clampDouble(r2, 0, 1),
      residualStd: math.sqrt(ssResidual / math.max(1, n - k)),
      sampleSize: n,
    );
  }

  double predict(List<double> row) => _dot(coefficients, row);

  static double _dot(List<double> a, List<double> b) {
    var sum = 0.0;
    for (var i = 0; i < a.length; i++) {
      sum += a[i] * b[i];
    }
    return sum;
  }

  /// Eliminação de Gauss com pivoteamento parcial.
  static List<double> _solve(List<List<double>> matrix, List<double> vector) {
    final n = vector.length;
    final a = [
      for (final row in matrix) [...row],
    ];
    final b = [...vector];

    for (var col = 0; col < n; col++) {
      var pivot = col;
      for (var row = col + 1; row < n; row++) {
        if (a[row][col].abs() > a[pivot][col].abs()) pivot = row;
      }
      if (pivot != col) {
        final tmpRow = a[col];
        a[col] = a[pivot];
        a[pivot] = tmpRow;
        final tmp = b[col];
        b[col] = b[pivot];
        b[pivot] = tmp;
      }
      final divisor = a[col][col];
      if (divisor.abs() < 1e-15) continue;
      for (var row = col + 1; row < n; row++) {
        final factor = a[row][col] / divisor;
        for (var c = col; c < n; c++) {
          a[row][c] -= factor * a[col][c];
        }
        b[row] -= factor * b[col];
      }
    }

    final x = List<double>.filled(n, 0);
    for (var row = n - 1; row >= 0; row--) {
      var sum = b[row];
      for (var c = row + 1; c < n; c++) {
        sum -= a[row][c] * x[c];
      }
      x[row] = a[row][row].abs() < 1e-15 ? 0 : sum / a[row][row];
    }
    return x;
  }
}
