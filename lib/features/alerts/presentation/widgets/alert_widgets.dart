import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/router/app_routes.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/theme/severity_colors.dart';
import '../../../../core/utils/formatters.dart';
import '../../application/alerts_providers.dart';
import '../../domain/territory_alert.dart';

extension AlertSeverityStyle on AlertSeverity {
  IconData get icon => switch (this) {
    AlertSeverity.low => Icons.info_outline,
    AlertSeverity.medium => Icons.warning_amber_rounded,
    AlertSeverity.high => Icons.error_outline,
  };

  Color color(BuildContext context) => switch (this) {
    AlertSeverity.low => context.severity.low,
    AlertSeverity.medium => context.severity.medium,
    AlertSeverity.high => context.severity.high,
  };
}

/// Ícone + rótulo da severidade. Cor nunca aparece sozinha.
class SeverityBadge extends StatelessWidget {
  const SeverityBadge({super.key, required this.severity, this.heroTag});

  final AlertSeverity severity;
  final String? heroTag;

  @override
  Widget build(BuildContext context) {
    final color = severity.color(context);
    final icon = Icon(severity.icon, color: color, size: 20);
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: 1.5),
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          heroTag == null ? icon : Hero(tag: heroTag!, child: icon),
          const SizedBox(width: AppSpacing.xs),
          Text(
            severity.label,
            style: Theme.of(context).textTheme.labelLarge
                ?.copyWith(color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }
}

/// Cartão de alerta usado nas listas. Toque abre o detalhe.
class AlertTile extends ConsumerWidget {
  const AlertTile({super.key, required this.alert, required this.today});

  final TerritoryAlert alert;
  final DateTime today;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final decision = ref.watch(decisionsProvider)[alert.id];
    final when = Fmt.relativeDay(alert.expectedDate, today);
    final confidence =
        'Confiança ${alert.confidenceLevel.label.toLowerCase()} '
        '(${Fmt.percent(alert.confidence)})';

    return Semantics(
      button: true,
      label:
          '${alert.severity.label}: ${alert.title}. ${alert.summary} '
          '$confidence. Previsto para $when. ${alert.sectorsLabel}. '
          '${decision == null ? 'Sem decisão registrada' : 'Decisão: ${decision.outcome.label}'}.',
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: () => context.goNamed(
              AppRoutes.alertDetail,
              pathParameters: {'alertId': alert.id},
            ),
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Wrap(
                    spacing: AppSpacing.sm,
                    runSpacing: AppSpacing.xs,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      SeverityBadge(
                        severity: alert.severity,
                        heroTag: 'alerta-${alert.id}',
                      ),
                      Text(
                        alert.kind.label,
                        style: theme.textTheme.labelMedium,
                      ),
                    ],
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Text(alert.title, style: theme.textTheme.titleMedium),
                  const SizedBox(height: AppSpacing.xs),
                  Text(
                    alert.summary,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: AppSpacing.sm),
                  Wrap(
                    spacing: AppSpacing.md,
                    runSpacing: AppSpacing.xs,
                    children: [
                      _Meta(icon: Icons.insights, text: confidence),
                      _Meta(icon: Icons.event, text: _cap(when)),
                      _Meta(
                        icon: Icons.place_outlined,
                        text: alert.sectorsLabel,
                      ),
                      _Meta(
                        icon: decision == null
                            ? Icons.pending_outlined
                            : Icons.how_to_reg_outlined,
                        text: decision == null
                            ? 'Aguardando decisão'
                            : decision.outcome.label,
                        emphasize: decision == null,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  static String _cap(String text) => text[0].toUpperCase() + text.substring(1);
}

class _Meta extends StatelessWidget {
  const _Meta({required this.icon, required this.text, this.emphasize = false});

  final IconData icon;
  final String text;
  final bool emphasize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final color = emphasize
        ? theme.colorScheme.primary
        : theme.colorScheme.onSurfaceVariant;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 16, color: color),
        const SizedBox(width: AppSpacing.xs),
        Flexible(
          child: Text(
            text,
            style: theme.textTheme.bodySmall?.copyWith(color: color),
          ),
        ),
      ],
    );
  }
}

/// Barra de confiança animada (0 a 100%) com o nível em texto.
class ConfidenceMeter extends StatelessWidget {
  const ConfidenceMeter({super.key, required this.confidence});

  final double confidence;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final level = ConfidenceLevel.of(confidence);
    final color = switch (level) {
      ConfidenceLevel.high => context.severity.low,
      ConfidenceLevel.medium => context.severity.medium,
      ConfidenceLevel.low => context.severity.high,
    };
    final reduceMotion = MediaQuery.disableAnimationsOf(context);

    return Semantics(
      label:
          'Nível de confiança ${level.label.toLowerCase()}, '
          '${Fmt.percent(confidence)}',
      child: ExcludeSemantics(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: level.label,
                    style: theme.textTheme.titleLarge?.copyWith(color: color),
                  ),
                  TextSpan(
                    text: '  ${Fmt.percent(confidence)}',
                    style: theme.textTheme.titleMedium,
                  ),
                ],
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: confidence),
              duration: reduceMotion
                  ? Duration.zero
                  : const Duration(milliseconds: 700),
              curve: Curves.easeOutCubic,
              builder: (context, value, _) => ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 12,
                  color: color,
                  backgroundColor: theme.colorScheme.surfaceContainerHighest,
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Baixa abaixo de 50% · Média de 50% a 74% · Alta a partir de 75%',
              style: theme.textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}
