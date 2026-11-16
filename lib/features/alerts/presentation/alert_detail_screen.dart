import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/human_decision_banner.dart';
import '../../../shared/widgets/state_views.dart';

/// Detalhe de um alerta. É o centro da nota (critério 3): deve mostrar a
/// evidência, o nível de confiança, as limitações e o aviso de decisão humana.
///
/// TODO: buscar o alerta pelo [alertId] e preencher as seções.
class AlertDetailScreen extends StatelessWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alerta')),
      body: Column(
        children: [
          const Padding(
            padding: AppSpacing.screen,
            child: HumanDecisionBanner(),
          ),
          Expanded(
            child: EmptyView(
              icon: Icons.fact_check_outlined,
              message: 'Detalhe do alerta "$alertId" em construção.',
            ),
          ),
        ],
      ),
    );
  }
}
