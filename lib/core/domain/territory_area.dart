import 'package:flutter/material.dart';

/// As três áreas do território, cada uma com seu dashboard.
///
/// O nome do valor (`clima`, `recursos`, `servicos`) é o parâmetro de rota:
/// `/painel/clima`, `/painel/recursos`, `/painel/servicos`.
enum TerritoryArea {
  clima(
    label: 'Clima local',
    description: 'Temperatura, chuva e ondas de calor',
    icon: Icons.thermostat_outlined,
  ),
  recursos(
    label: 'Água e energia',
    description: 'Consumo, perdas e desperdício',
    icon: Icons.water_drop_outlined,
  ),
  servicos(
    label: 'Serviços públicos',
    description: 'Demanda por saúde, coleta e transporte',
    icon: Icons.local_hospital_outlined,
  );

  const TerritoryArea({
    required this.label,
    required this.description,
    required this.icon,
  });

  final String label;
  final String description;
  final IconData icon;

  /// Converte o parâmetro de rota. Retorna `null` se a área não existir.
  static TerritoryArea? fromPath(String? value) => values.asNameMap()[value];
}
