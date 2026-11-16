import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/territory_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/feedback.dart';
import '../../../shared/widgets/state_views.dart';
import '../application/occurrences_controller.dart';

/// Relatos feitos neste aparelho.
class OccurrencesListScreen extends ConsumerWidget {
  const OccurrencesListScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final items = ref.watch(occurrencesProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Meus relatos')),
      body: items.isEmpty
          ? EmptyView(
              icon: Icons.edit_note,
              message: 'Você ainda não fez nenhum relato.',
              action: FilledButton(
                onPressed: () => context.goNamed(AppRoutes.report),
                child: const Text('Relatar ocorrência'),
              ),
            )
          : ListView.separated(
              padding: AppSpacing.screen,
              itemCount: items.length,
              separatorBuilder: (_, _) => const SizedBox(height: AppSpacing.sm),
              itemBuilder: (context, index) {
                final item = items[index];
                final sector = TerritoryConfig.sectorById(item.sectorId);
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(
                      AppSpacing.md,
                      AppSpacing.sm,
                      AppSpacing.xs,
                      AppSpacing.md,
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                item.type.label,
                                style: theme.textTheme.titleMedium,
                              ),
                            ),
                            IconButton(
                              tooltip: 'Apagar relato',
                              icon: const Icon(Icons.delete_outline),
                              onPressed: () async {
                                await ref
                                    .read(occurrencesProvider.notifier)
                                    .remove(item.id);
                                if (!context.mounted) return;
                                showFeedback(context, 'Relato apagado.');
                              },
                            ),
                          ],
                        ),
                        Text(
                          '${sector.name} · ${Fmt.day(item.occurredOn)} · '
                          'gravidade ${item.severity.label.toLowerCase()}',
                          style: theme.textTheme.bodySmall,
                        ),
                        const SizedBox(height: AppSpacing.sm),
                        Padding(
                          padding: const EdgeInsets.only(right: AppSpacing.sm),
                          child: Text(item.description),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}
