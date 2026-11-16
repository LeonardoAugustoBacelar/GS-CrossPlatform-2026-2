import 'package:flutter/material.dart';

import 'severity_colors.dart';

/// Paleta da identidade visual do Mirante.
///
/// Nenhuma tela deve declarar cores soltas: use `Theme.of(context).colorScheme`
/// ou `context.severity` (cores de severidade dos alertas).
abstract final class AppColors {
  /// Azul-petróleo: cor-semente do ColorScheme.
  static const Color brand = Color(0xFF0B5C6B);

  static const SeverityColors severityLight = SeverityColors(
    low: Color(0xFF1B6E2A),
    medium: Color(0xFF8A5300),
    high: Color(0xFFB3261E),
  );

  static const SeverityColors severityDark = SeverityColors(
    low: Color(0xFF8FD99B),
    medium: Color(0xFFFFC266),
    high: Color(0xFFFFB4AB),
  );
}
