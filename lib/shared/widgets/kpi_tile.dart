import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';
import '../../core/theme/severity_colors.dart';
import '../../core/utils/formatters.dart';

/// Número de destaque com unidade e tendência semanal.
class KpiTile extends StatelessWidget {
  const KpiTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.change,
    this.higherIsWorse = true,
    this.caption,
    this.onTap,
  });

  final String label;
  final String value;
  final String? unit;

  /// Variação relativa (0,05 = +5%) em relação à semana anterior.
  final double? change;
  final bool higherIsWorse;
  final String? caption;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final change = this.change;
    final changeText = change == null
        ? null
        : '${change >= 0 ? '+' : '−'}${Fmt.percent(change.abs(), decimals: 1)} na semana';
    final worse =
        change != null &&
        (change > 0.005) == higherIsWorse &&
        change.abs() > 0.005;
    final better = change != null && !worse && change.abs() > 0.005;
    final changeColor = worse
        ? context.severity.high
        : (better ? context.severity.low : theme.colorScheme.onSurfaceVariant);

    return Semantics(
      button: onTap != null,
      label: [label, '$value ${unit ?? ''}', ?changeText, ?caption].join(', '),
      child: ExcludeSemantics(
        child: Card(
          clipBehavior: Clip.antiAlias,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.all(AppSpacing.md),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: AppSpacing.xs),
                  Text.rich(
                    TextSpan(
                      children: [
                        TextSpan(
                          text: value,
                          style: theme.textTheme.headlineSmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        if (unit != null)
                          TextSpan(
                            text: ' $unit',
                            style: theme.textTheme.bodyMedium,
                          ),
                      ],
                    ),
                  ),
                  if (changeText != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Row(
                      children: [
                        Icon(
                          change! >= 0
                              ? Icons.trending_up
                              : Icons.trending_down,
                          size: 18,
                          color: changeColor,
                        ),
                        const SizedBox(width: AppSpacing.xs),
                        Flexible(
                          child: Text(
                            changeText,
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: changeColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                  if (caption != null) ...[
                    const SizedBox(height: AppSpacing.xs),
                    Text(caption!, style: theme.textTheme.bodySmall),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Grade responsiva de KPIs: 3 por linha em telas largas, 2 em celulares e
/// 1 quando a fonte está muito ampliada.
class KpiGrid extends StatelessWidget {
  const KpiGrid({super.key, required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    final textScale = MediaQuery.textScalerOf(context).scale(1);
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = textScale >= 1.4
            ? 1
            : (width >= 600 ? 3 : (width >= 300 ? 2 : 1));
        final itemWidth = (width - AppSpacing.sm * (columns - 1)) / columns;
        return Wrap(
          spacing: AppSpacing.sm,
          runSpacing: AppSpacing.sm,
          children: [
            for (final child in children)
              SizedBox(width: itemWidth, child: child),
          ],
        );
      },
    );
  }
}
