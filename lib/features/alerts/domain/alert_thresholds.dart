/// Limiares de alerta configuráveis pelo gestor (formulário em Ajustes).
enum ThresholdField {
  heatTemperature(
    label: 'Temperatura máxima (onda de calor)',
    unit: '°C',
    min: 28,
    max: 42,
    defaultValue: 32,
    decimals: 1,
    help: 'Dias com máxima prevista a partir deste valor contam como calor.',
  ),
  heatDays(
    label: 'Dias seguidos de calor',
    unit: 'dias',
    min: 1,
    max: 5,
    defaultValue: 2,
    help: 'Quantos dias seguidos acima do limite disparam o alerta.',
  ),
  rainMm(
    label: 'Chuva forte em um dia',
    unit: 'mm',
    min: 10,
    max: 150,
    defaultValue: 30,
    help: 'Chuva prevista a partir deste volume indica risco de alagamento.',
  ),
  pm25(
    label: 'Partículas finas (PM2,5)',
    unit: 'µg/m³',
    min: 10,
    max: 75,
    defaultValue: 25,
    help: 'Padrão: meta intermediária da OMS. A diretriz final é 15.',
  ),
  waterIncrease(
    label: 'Aumento do consumo de água',
    unit: '%',
    min: 3,
    max: 30,
    defaultValue: 8,
    help: 'Em relação à média dos últimos 30 dias.',
  ),
  waterLoss(
    label: 'Perdas na distribuição',
    unit: '%',
    min: 20,
    max: 50,
    defaultValue: 35,
    help: 'Média de 7 dias de um setor acima deste valor gera alerta.',
  ),
  healthOccupancy(
    label: 'Ocupação prevista das UBS',
    unit: '%',
    min: 60,
    max: 120,
    defaultValue: 90,
    help: 'Percentual da capacidade diária de atendimento do setor.',
  ),
  wasteIncrease(
    label: 'Aumento de solicitações de coleta',
    unit: '%',
    min: 10,
    max: 100,
    defaultValue: 30,
    help: 'Média de 7 dias em relação aos 30 dias anteriores.',
  );

  const ThresholdField({
    required this.label,
    required this.unit,
    required this.min,
    required this.max,
    required this.defaultValue,
    required this.help,
    this.decimals = 0,
  });

  final String label;
  final String unit;
  final double min;
  final double max;
  final double defaultValue;
  final String help;
  final int decimals;

  /// Converte o texto digitado (aceita vírgula decimal).
  static double? parse(String? raw) =>
      double.tryParse((raw ?? '').trim().replaceAll(',', '.'));

  /// Mensagem de erro para o texto digitado, ou `null` se for válido.
  String? validate(String? raw) {
    if (raw == null || raw.trim().isEmpty) return 'Informe um valor.';
    final value = parse(raw);
    if (value == null) return 'Use apenas números.';
    if (decimals == 0 && value != value.roundToDouble()) {
      return 'Use um número inteiro.';
    }
    if (value < min || value > max) {
      return 'Use um valor entre ${_format(min)} e ${_format(max)} $unit.';
    }
    return null;
  }

  String format(double value) => _format(value);

  String _format(double value) => decimals == 0 || value == value.truncate()
      ? value.toStringAsFixed(0)
      : value.toStringAsFixed(decimals).replaceAll('.', ',');
}

class AlertThresholds {
  const AlertThresholds([this._values = const {}]);

  factory AlertThresholds.fromJson(Map<String, dynamic> json) =>
      AlertThresholds({
        for (final field in ThresholdField.values)
          if (json[field.name] is num)
            field: (json[field.name] as num).toDouble(),
      });

  final Map<ThresholdField, double> _values;

  double operator [](ThresholdField field) =>
      _values[field] ?? field.defaultValue;

  bool get isDefault =>
      ThresholdField.values.every((field) => this[field] == field.defaultValue);

  AlertThresholds copyWith(Map<ThresholdField, double> changes) =>
      AlertThresholds({..._values, ...changes});

  Map<String, double> toJson() => {
    for (final field in ThresholdField.values) field.name: this[field],
  };
}
