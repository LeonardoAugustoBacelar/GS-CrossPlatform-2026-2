import 'package:flutter/widgets.dart';

/// Espaçamentos e raios padronizados. Use estes valores em vez de números soltos.
abstract final class AppSpacing {
  static const double xs = 4;
  static const double sm = 8;
  static const double md = 16;
  static const double lg = 24;
  static const double xl = 32;

  static const double radius = 16;

  /// Área mínima de toque recomendada para acessibilidade.
  static const double minTouchTarget = 48;

  static const EdgeInsets screen = EdgeInsets.all(md);
}
