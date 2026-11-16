import 'package:flutter/material.dart';

/// Cores de severidade dos alertas, com uma versão para cada tema.
///
/// Severidade nunca é comunicada só pela cor: sempre acompanhe com ícone e
/// texto, para quem não distingue cores e para leitores de tela.
@immutable
class SeverityColors extends ThemeExtension<SeverityColors> {
  const SeverityColors({
    required this.low,
    required this.medium,
    required this.high,
  });

  final Color low;
  final Color medium;
  final Color high;

  @override
  SeverityColors copyWith({Color? low, Color? medium, Color? high}) {
    return SeverityColors(
      low: low ?? this.low,
      medium: medium ?? this.medium,
      high: high ?? this.high,
    );
  }

  @override
  SeverityColors lerp(SeverityColors? other, double t) {
    if (other == null) return this;
    return SeverityColors(
      low: Color.lerp(low, other.low, t)!,
      medium: Color.lerp(medium, other.medium, t)!,
      high: Color.lerp(high, other.high, t)!,
    );
  }
}

extension SeverityColorsContext on BuildContext {
  SeverityColors get severity => Theme.of(this).extension<SeverityColors>()!;
}
