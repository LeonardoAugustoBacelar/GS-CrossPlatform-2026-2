import 'package:flutter/material.dart';

import '../../core/theme/app_spacing.dart';

/// Aviso exigido pelo desafio: os alertas apoiam, mas não substituem, a
/// decisão humana. Deve aparecer na visão geral, na lista e no detalhe de alertas.
class HumanDecisionBanner extends StatelessWidget {
  const HumanDecisionBanner({super.key});

  static const _text =
      'Os alertas são previsões com incerteza. Eles apoiam, mas não '
      'substituem, a decisão de uma pessoa responsável.';

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Semantics(
      container: true,
      label: 'Aviso: $_text',
      child: ExcludeSemantics(
        child: Card(
          color: scheme.secondaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.person_outline, color: scheme.onSecondaryContainer),
                const SizedBox(width: AppSpacing.md),
                Expanded(
                  child: Text(
                    _text,
                    style: TextStyle(color: scheme.onSecondaryContainer),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
