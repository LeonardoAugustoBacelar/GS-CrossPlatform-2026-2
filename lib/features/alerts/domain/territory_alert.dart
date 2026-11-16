import '../../../core/config/territory_config.dart';
import '../../../core/domain/territory_area.dart';

enum AlertSeverity {
  low('Observação'),
  medium('Atenção'),
  high('Crítico');

  const AlertSeverity(this.label);
  final String label;
}

enum ConfidenceLevel {
  low('Baixa'),
  medium('Média'),
  high('Alta');

  const ConfidenceLevel(this.label);
  final String label;

  static ConfidenceLevel of(double confidence) => confidence >= 0.75
      ? ConfidenceLevel.high
      : (confidence >= 0.5 ? ConfidenceLevel.medium : ConfidenceLevel.low);
}

enum AlertKind {
  heatWave('Onda de calor'),
  heavyRain('Chuva forte'),
  airQuality('Qualidade do ar'),
  waterDemand('Pico de consumo de água'),
  waterLoss('Perdas de água'),
  energyAnomaly('Consumo de energia fora do padrão'),
  healthDemand('Demanda nas UBS'),
  wasteRequests('Descarte irregular de lixo'),
  citizenReports('Relatos de cidadãos');

  const AlertKind(this.label);
  final String label;
}

/// Alerta gerado a partir dos dados. Sempre traz a evidência, a confiança e
/// as limitações. O app só **sugere**: a decisão é de uma pessoa.
class TerritoryAlert {
  const TerritoryAlert({
    required this.id,
    required this.kind,
    required this.area,
    required this.severity,
    required this.title,
    required this.summary,
    required this.evidence,
    required this.confidence,
    required this.confidenceReason,
    required this.limitations,
    required this.suggestedAction,
    required this.sectorIds,
    required this.indicatorId,
    required this.expectedDate,
    this.benefit,
  });

  /// Estável entre execuções (tipo + setor), para guardar a decisão humana.
  final String id;
  final AlertKind kind;
  final TerritoryArea area;
  final AlertSeverity severity;
  final String title;
  final String summary;

  /// Fatos dos dados que justificam o alerta.
  final List<String> evidence;

  /// Entre 0 e 1.
  final double confidence;
  final String confidenceReason;

  /// Limitações e situações em que o alerta não é confiável.
  final List<String> limitations;

  /// Sugestão para avaliação humana. Nunca é executada pelo app.
  final String suggestedAction;
  final List<String> sectorIds;
  final String indicatorId;

  /// Dia em que o problema é esperado (ou foi detectado).
  final DateTime expectedDate;

  /// Benefício social potencial de agir a tempo.
  final String? benefit;

  ConfidenceLevel get confidenceLevel => ConfidenceLevel.of(confidence);

  int get population => sectorIds.fold(
    0,
    (sum, id) => sum + TerritoryConfig.sectorById(id).population,
  );

  String get sectorsLabel => sectorIds.length == TerritoryConfig.sectors.length
      ? 'Todo o território'
      : sectorIds.map((id) => TerritoryConfig.sectorById(id).name).join(', ');
}
