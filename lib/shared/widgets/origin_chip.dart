import 'package:flutter/material.dart';

import '../../core/domain/indicator.dart';
import '../../core/theme/app_spacing.dart';

/// Etiqueta que deixa claro se o dado é real ou sintético (transparência).
class OriginChip extends StatelessWidget {
  const OriginChip({super.key, required this.origin});

  final DataOrigin origin;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final real = origin == DataOrigin.real;
    final background = real
        ? scheme.primaryContainer
        : scheme.tertiaryContainer;
    final foreground = real
        ? scheme.onPrimaryContainer
        : scheme.onTertiaryContainer;
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: AppSpacing.sm,
        vertical: AppSpacing.xs,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(AppSpacing.radius),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            real ? Icons.public : Icons.science_outlined,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: AppSpacing.xs),
          Text(
            origin.label,
            style: Theme.of(context).textTheme.labelSmall
                ?.copyWith(color: foreground),
          ),
        ],
      ),
    );
  }
}
