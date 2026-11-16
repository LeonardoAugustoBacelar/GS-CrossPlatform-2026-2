import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/human_decision_banner.dart';
import '../../../shared/widgets/state_views.dart';

/// Lista de alertas gerados a partir dos dados.
///
/// TODO: ler os alertas do provider e mostrar severidade (ícone + texto + cor).
class AlertsScreen extends StatelessWidget {
  const AlertsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Alertas')),
      body: const Column(
        children: [
          Padding(padding: AppSpacing.screen, child: HumanDecisionBanner()),
          Expanded(
            child: EmptyView(
              icon: Icons.notifications_none,
              message: 'Nenhum alerta no momento.',
            ),
          ),
        ],
      ),
    );
  }
}
