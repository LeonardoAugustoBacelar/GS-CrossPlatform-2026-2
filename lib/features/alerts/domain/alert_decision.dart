enum DecisionOutcome {
  planned('Ação planejada'),
  monitor('Monitorar'),
  dismissed('Falso alarme');

  const DecisionOutcome(this.label);
  final String label;
}

/// Decisão registrada por uma pessoa sobre um alerta.
class AlertDecision {
  const AlertDecision({
    required this.alertId,
    required this.outcome,
    required this.note,
    required this.decidedAt,
  });

  factory AlertDecision.fromJson(Map<String, dynamic> json) => AlertDecision(
    alertId: json['alertId'] as String,
    outcome: DecisionOutcome.values.byName(json['outcome'] as String),
    note: json['note'] as String? ?? '',
    decidedAt: DateTime.parse(json['decidedAt'] as String),
  );

  final String alertId;
  final DecisionOutcome outcome;
  final String note;
  final DateTime decidedAt;

  Map<String, dynamic> toJson() => {
    'alertId': alertId,
    'outcome': outcome.name,
    'note': note,
    'decidedAt': decidedAt.toIso8601String(),
  };
}
