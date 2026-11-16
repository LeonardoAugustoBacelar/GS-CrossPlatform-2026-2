import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/state_views.dart';

/// Detalhe de um indicador: série histórica, tendência e alertas relacionados.
///
/// TODO: buscar o indicador pelo [indicatorId] e listar os alertas ligados a ele.
class IndicatorDetailScreen extends StatelessWidget {
  const IndicatorDetailScreen({super.key, required this.indicatorId});

  final String indicatorId;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Indicador')),
      body: EmptyView(
        icon: Icons.show_chart,
        message: 'Detalhe do indicador "$indicatorId" em construção.',
        action: OutlinedButton(
          onPressed: () => context.goNamed(
            AppRoutes.alertDetail,
            pathParameters: {'alertId': 'exemplo'},
          ),
          child: const Text('Abrir alerta de exemplo'),
        ),
      ),
    );
  }
}
