import '../../../core/domain/time_series.dart';

enum OccurrenceType {
  flooding('Alagamento'),
  waterShortage('Falta d’água'),
  leak('Vazamento de água'),
  garbage('Lixo acumulado'),
  heat('Calor extremo'),
  other('Outro');

  const OccurrenceType(this.label);
  final String label;
}

enum OccurrenceSeverity {
  low('Leve'),
  medium('Moderada'),
  high('Grave');

  const OccurrenceSeverity(this.label);
  final String label;
}

/// Relato anônimo de um cidadão. Não guarda nome, contato nem endereço:
/// a localização é só o setor.
class Occurrence {
  const Occurrence({
    required this.id,
    required this.type,
    required this.sectorId,
    required this.description,
    required this.severity,
    required this.occurredOn,
    required this.createdAt,
  });

  factory Occurrence.fromJson(Map<String, dynamic> json) => Occurrence(
    id: json['id'] as String,
    type: OccurrenceType.values.byName(json['type'] as String),
    sectorId: json['sectorId'] as String,
    description: json['description'] as String,
    severity: OccurrenceSeverity.values.byName(json['severity'] as String),
    occurredOn: parseDateKey(json['occurredOn'] as String),
    createdAt: DateTime.parse(json['createdAt'] as String),
  );

  final String id;
  final OccurrenceType type;
  final String sectorId;
  final String description;
  final OccurrenceSeverity severity;
  final DateTime occurredOn;
  final DateTime createdAt;

  Map<String, dynamic> toJson() => {
    'id': id,
    'type': type.name,
    'sectorId': sectorId,
    'description': description,
    'severity': severity.name,
    'occurredOn': dateKey(occurredOn),
    'createdAt': createdAt.toIso8601String(),
  };
}
