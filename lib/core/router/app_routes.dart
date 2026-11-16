/// Nomes das rotas. Navegue sempre pelo nome, nunca pelo caminho:
///
/// ```dart
/// context.goNamed(
///   AppRoutes.alertDetail,
///   pathParameters: {'alertId': alerta.id},
/// );
/// ```
abstract final class AppRoutes {
  static const consent = 'consentimento';
  static const overview = 'visao-geral';
  static const map = 'mapa';
  static const dashboard = 'painel';
  static const indicatorDetail = 'indicador';
  static const alerts = 'alertas';
  static const alertDetail = 'alerta';
  static const report = 'relatar';
  static const occurrences = 'meus-relatos';
  static const settings = 'ajustes';
  static const thresholds = 'limiares';
}
