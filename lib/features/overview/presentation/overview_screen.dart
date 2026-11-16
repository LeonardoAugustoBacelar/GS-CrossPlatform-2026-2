import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/territory_config.dart';
import '../../../core/domain/territory_area.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/widgets/human_decision_banner.dart';

/// Visão geral do território: ponto de partida para os três dashboards.
///
/// TODO: resumo dos alertas ativos e o indicador de benefício social.
class OverviewScreen extends StatelessWidget {
  const OverviewScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Visão geral'),
        bottom: const PreferredSize(
          preferredSize: Size.fromHeight(AppSpacing.lg),
          child: Padding(
            padding: EdgeInsets.only(
              left: AppSpacing.md,
              bottom: AppSpacing.sm,
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '${TerritoryConfig.name} · ${TerritoryConfig.region}',
              ),
            ),
          ),
        ),
      ),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const HumanDecisionBanner(),
          const SizedBox(height: AppSpacing.lg),
          for (final area in TerritoryArea.values) ...[
            _AreaCard(area: area),
            const SizedBox(height: AppSpacing.md),
          ],
        ],
      ),
    );
  }
}

class _AreaCard extends StatelessWidget {
  const _AreaCard({required this.area});

  final TerritoryArea area;

  @override
  Widget build(BuildContext context) {
    return Card(
      clipBehavior: Clip.antiAlias,
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: AppSpacing.md,
          vertical: AppSpacing.sm,
        ),
        leading: Icon(area.icon, size: 32),
        title: Text(area.label),
        subtitle: Text(area.description),
        trailing: const Icon(Icons.chevron_right),
        onTap: () => context.goNamed(
          AppRoutes.dashboard,
          pathParameters: {'area': area.name},
        ),
      ),
    );
  }
}
