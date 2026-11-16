import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/feedback.dart';
import '../../../shared/widgets/human_decision_banner.dart';
import '../../../shared/widgets/section_card.dart';
import '../../../shared/widgets/state_views.dart';
import '../../occurrences/domain/occurrence_validators.dart';
import '../application/alerts_providers.dart';
import '../domain/alert_decision.dart';
import '../domain/territory_alert.dart';
import 'widgets/alert_widgets.dart';

/// Detalhe do alerta: evidência, confiança, limitações, benefício social e o
/// registro da decisão humana. O app não executa nenhuma ação sozinho.
class AlertDetailScreen extends ConsumerWidget {
  const AlertDetailScreen({super.key, required this.alertId});

  final String alertId;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final alert = ref.watch(alertProvider(alertId));
    return Scaffold(
      appBar: AppBar(title: const Text('Detalhe do alerta')),
      body: AsyncValueView<TerritoryAlert?>(
        value: alert,
        errorMessage: 'Não foi possível carregar o alerta.',
        onRetry: () => ref.invalidate(alertReportProvider),
        builder: (alert) => alert == null
            ? EmptyView(
                icon: Icons.notifications_off_outlined,
                message:
                    'Este alerta não está mais ativo. Os dados ou os '
                    'limiares mudaram desde que ele foi gerado.',
                action: FilledButton(
                  onPressed: () => context.goNamed(AppRoutes.alerts),
                  child: const Text('Ver alertas ativos'),
                ),
              )
            : _AlertDetail(alert: alert),
      ),
    );
  }
}

class _AlertDetail extends ConsumerWidget {
  const _AlertDetail({required this.alert});

  final TerritoryAlert alert;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final today = ref.watch(clockProvider)();
    final color = alert.severity.color(context);

    return ListView(
      padding: AppSpacing.screen,
      children: [
        Card(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(AppSpacing.radius),
            side: BorderSide(color: color, width: 2),
          ),
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.md),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Wrap(
                  spacing: AppSpacing.sm,
                  crossAxisAlignment: WrapCrossAlignment.center,
                  children: [
                    SeverityBadge(
                      severity: alert.severity,
                      heroTag: 'alerta-${alert.id}',
                    ),
                    Text(alert.kind.label, style: theme.textTheme.labelLarge),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),
                Semantics(
                  header: true,
                  child: Text(
                    alert.title,
                    style: theme.textTheme.headlineSmall,
                  ),
                ),
                const SizedBox(height: AppSpacing.sm),
                Text(alert.summary, style: theme.textTheme.bodyLarge),
                const SizedBox(height: AppSpacing.md),
                _InfoRow(
                  icon: Icons.event,
                  text:
                      '${_cap(Fmt.relativeDay(alert.expectedDate, today))}: '
                      '${Fmt.weekdayDay(alert.expectedDate)}',
                ),
                _InfoRow(
                  icon: Icons.place_outlined,
                  text:
                      '${alert.sectorsLabel} · '
                      '${Fmt.compact(alert.population)} moradores',
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        const HumanDecisionBanner(),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Por que este alerta?',
          subtitle: 'Evidências encontradas nos dados',
          icon: Icons.fact_check_outlined,
          child: BulletList(
            items: alert.evidence,
            icon: Icons.check,
            iconSize: 18,
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Nível de confiança',
          icon: Icons.insights,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              ConfidenceMeter(confidence: alert.confidence),
              const SizedBox(height: AppSpacing.md),
              Text(alert.confidenceReason),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Limitações e quando não confiar',
          icon: Icons.report_problem_outlined,
          child: BulletList(
            items: alert.limitations,
            icon: Icons.remove,
            iconSize: 18,
            iconColor: theme.colorScheme.error,
          ),
        ),
        if (alert.benefit != null) ...[
          const SizedBox(height: AppSpacing.md),
          SectionCard(
            title: 'Benefício social de agir a tempo',
            icon: Icons.volunteer_activism_outlined,
            child: Text(alert.benefit!),
          ),
        ],
        const SizedBox(height: AppSpacing.md),
        SectionCard(
          title: 'Ação sugerida para avaliação',
          icon: Icons.lightbulb_outline,
          child: Text(alert.suggestedAction),
        ),
        const SizedBox(height: AppSpacing.md),
        _DecisionSection(alert: alert),
        const SizedBox(height: AppSpacing.md),
        OutlinedButton.icon(
          onPressed: () => context.goNamed(
            AppRoutes.indicatorDetail,
            pathParameters: {
              'area': alert.area.name,
              'indicatorId': alert.indicatorId,
            },
          ),
          icon: const Icon(Icons.show_chart),
          label: const Text('Ver o indicador e o histórico'),
        ),
        const SizedBox(height: AppSpacing.lg),
      ],
    );
  }

  static String _cap(String text) => text[0].toUpperCase() + text.substring(1);
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: AppSpacing.xs),
      child: Row(
        children: [
          ExcludeSemantics(child: Icon(icon, size: 18)),
          const SizedBox(width: AppSpacing.sm),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}

/// Registro da decisão humana sobre o alerta (guardado no aparelho).
class _DecisionSection extends ConsumerStatefulWidget {
  const _DecisionSection({required this.alert});

  final TerritoryAlert alert;

  @override
  ConsumerState<_DecisionSection> createState() => _DecisionSectionState();
}

class _DecisionSectionState extends ConsumerState<_DecisionSection> {
  final _formKey = GlobalKey<FormState>();
  final _note = TextEditingController();
  DecisionOutcome? _outcome;
  bool _editing = false;

  @override
  void dispose() {
    _note.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_outcome == null || !_formKey.currentState!.validate()) return;
    await ref
        .read(decisionsProvider.notifier)
        .record(
          AlertDecision(
            alertId: widget.alert.id,
            outcome: _outcome!,
            note: _note.text.trim(),
            decidedAt: ref.read(clockProvider)(),
          ),
        );
    if (!mounted) return;
    setState(() => _editing = false);
    showFeedback(context, 'Decisão registrada.');
  }

  @override
  Widget build(BuildContext context) {
    final decision = ref.watch(decisionsProvider)[widget.alert.id];
    final theme = Theme.of(context);

    if (decision != null && !_editing) {
      return SectionCard(
        title: 'Sua decisão',
        icon: Icons.how_to_reg_outlined,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(decision.outcome.label, style: theme.textTheme.titleMedium),
            if (decision.note.isNotEmpty) ...[
              const SizedBox(height: AppSpacing.xs),
              Text(decision.note),
            ],
            const SizedBox(height: AppSpacing.xs),
            Text(
              'Registrada em ${Fmt.dateTime(decision.decidedAt)}',
              style: theme.textTheme.bodySmall,
            ),
            const SizedBox(height: AppSpacing.sm),
            TextButton.icon(
              onPressed: () => setState(() {
                _editing = true;
                _outcome = decision.outcome;
                _note.text = decision.note;
              }),
              icon: const Icon(Icons.edit_outlined),
              label: const Text('Alterar decisão'),
            ),
          ],
        ),
      );
    }

    return SectionCard(
      title: 'Registrar decisão',
      subtitle:
          'O Mirante não executa nenhuma ação. Registre o que a equipe '
          'decidiu depois de avaliar o alerta.',
      icon: Icons.how_to_reg_outlined,
      child: Form(
        key: _formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Wrap(
              spacing: AppSpacing.sm,
              runSpacing: AppSpacing.sm,
              children: [
                for (final outcome in DecisionOutcome.values)
                  ChoiceChip(
                    label: Text(outcome.label),
                    selected: _outcome == outcome,
                    onSelected: (_) => setState(() => _outcome = outcome),
                  ),
              ],
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _note,
              maxLength: 200,
              maxLines: 2,
              decoration: const InputDecoration(
                labelText: 'Observação (opcional)',
                hintText: 'Ex.: equipe de vistoria agendada para amanhã',
              ),
              validator: (value) =>
                  OccurrenceValidators.containsPersonalData(value ?? '')
                  ? 'Não inclua dados pessoais na observação.'
                  : null,
            ),
            const SizedBox(height: AppSpacing.sm),
            FilledButton(
              onPressed: _outcome == null ? null : _save,
              child: const Text('Registrar decisão'),
            ),
          ],
        ),
      ),
    );
  }
}
