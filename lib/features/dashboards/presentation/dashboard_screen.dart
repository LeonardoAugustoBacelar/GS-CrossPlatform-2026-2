import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/territory_area.dart';
import '../../../core/router/app_routes.dart';
import '../../../shared/widgets/state_views.dart';

/// Dashboard de uma área do território.
///
/// TODO: cada área terá o seu dashboard (gráficos com histórico e tendência,
/// cards de indicadores). Este esqueleto só demonstra a navegação com parâmetros.
class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key, required this.area});

  final TerritoryArea area;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(area.label)),
      body: EmptyView(
        icon: area.icon,
        message: 'Dashboard de ${area.label.toLowerCase()} em construção.',
        action: OutlinedButton(
          onPressed: () => context.goNamed(
            AppRoutes.indicatorDetail,
            pathParameters: {'area': area.name, 'indicatorId': 'exemplo'},
          ),
          child: const Text('Abrir indicador de exemplo'),
        ),
      ),
    );
  }
}
