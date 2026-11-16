import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/domain/indicator.dart';
import '../../../core/domain/territory_area.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/refresh.dart';
import '../../../shared/widgets/data_status_banner.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../alerts/presentation/widgets/alert_widgets.dart';
import '../../indicators/application/indicators_providers.dart';

/// Estrutura comum dos três dashboards: carregamento, erro, atualizar,
/// aviso offline, alertas da área e fonte dos dados.
class DashboardScaffold extends ConsumerWidget {
  const DashboardScaffold({
    super.key,
    required this.area,
    required this.builder,
    this.errorMessage = 'Não foi possível carregar os dados desta área.',
  });

  final TerritoryArea area;
  final String errorMessage;
  final List<Widget> Function(
    BuildContext context,
    Map<String, Indicator> indicators,
  )
  builder;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final indicators = ref.watch(areaIndicatorsProvider(area));

    return Scaffold(
      appBar: AppBar(
        title: Text(area.label),
        actions: [
          IconButton(
            tooltip: 'Atualizar dados',
            icon: const Icon(Icons.refresh),
            onPressed: () => refreshTerritoryData(ref),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => refreshTerritoryData(ref),
        child: AsyncValueView(
          value: indicators,
          errorMessage: errorMessage,
          onRetry: () => refreshTerritoryData(ref),
          isEmpty: (list) => list.isEmpty,
          emptyMessage: 'Ainda não há dados para esta área.',
          builder: (list) {
            final byId = {for (final i in list) i.id: i};
            final first = list.first;
            return ListView(
              padding: AppSpacing.screen,
              children: [
                if (first.fromCache) ...[
                  OfflineBanner(savedAt: first.updatedAt),
                  const SizedBox(height: AppSpacing.md),
                ],
                Text(
                  area.description,
                  style: Theme.of(context).textTheme.bodyLarge,
                ),
                const SizedBox(height: AppSpacing.md),
                for (final widget in builder(context, byId)) ...[
                  widget,
                  const SizedBox(height: AppSpacing.md),
                ],
                _AreaAlerts(area: area),
                SourceNote(
                  text:
                      'Fonte: ${first.source}. '
                      '${first.origin.label}. Atualizado em '
                      '${Fmt.dateTime(first.fromCache ? first.updatedAt : ref.watch(clockProvider)())}.',
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

/// Botão "Ver detalhes" que leva ao indicador (rota com parâmetros).
class IndicatorDetailsButton extends StatelessWidget {
  const IndicatorDetailsButton({super.key, required this.indicator});

  final Indicator indicator;

  @override
  Widget build(BuildContext context) {
    return Align(
      alignment: Alignment.centerRight,
      child: TextButton.icon(
        onPressed: () => openIndicator(context, indicator),
        icon: const Icon(Icons.arrow_forward),
        // O leitor de tela diz de qual indicador são os detalhes.
        label: Text(
          'Ver detalhes',
          semanticsLabel: 'Ver detalhes de ${indicator.name}',
        ),
      ),
    );
  }
}

void openIndicator(BuildContext context, Indicator indicator) =>
    context.goNamed(
      AppRoutes.indicatorDetail,
      pathParameters: {
        'area': indicator.area.name,
        'indicatorId': indicator.id,
      },
    );

class _AreaAlerts extends ConsumerWidget {
  const _AreaAlerts({required this.area});

  final TerritoryArea area;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final report = ref.watch(alertReportProvider);
    final today = ref.watch(clockProvider)();
    return SectionCard(
      title: 'Alertas desta área',
      icon: Icons.notifications_active_outlined,
      child: switch (report) {
        AsyncData(:final value) => () {
          final alerts = value.alerts.where((a) => a.area == area).toList();
          if (alerts.isEmpty) {
            return const Text(
              'Nenhum alerta nesta área com os limiares atuais.',
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              for (final alert in alerts)
                Padding(
                  padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                  child: AlertTile(alert: alert, today: today),
                ),
            ],
          );
        }(),
        AsyncError() => const Text('Não foi possível avaliar os alertas.'),
        _ => const LinearProgressIndicator(),
      },
    );
  }
}
