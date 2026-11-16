import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/territory_config.dart';
import '../../../core/domain/time_series.dart';
import '../../../core/providers.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/feedback.dart';
import '../application/occurrences_controller.dart';
import '../domain/occurrence.dart';
import '../domain/occurrence_validators.dart';

/// Formulário de ocorrência do cidadão: anônimo, validado e salvo no
/// aparelho (funciona sem conexão).
class OccurrenceFormScreen extends ConsumerStatefulWidget {
  const OccurrenceFormScreen({super.key});

  @override
  ConsumerState<OccurrenceFormScreen> createState() =>
      _OccurrenceFormScreenState();
}

class _OccurrenceFormScreenState extends ConsumerState<OccurrenceFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _description = TextEditingController();
  OccurrenceType? _type;
  String? _sectorId;
  DateTime? _date;
  OccurrenceSeverity _severity = OccurrenceSeverity.medium;
  bool _submitting = false;
  int _formVersion = 0;

  @override
  void dispose() {
    _description.dispose();
    super.dispose();
  }

  Future<void> _pickDate(FormFieldState<DateTime> field) async {
    final today = ref.read(clockProvider)();
    final picked = await showDatePicker(
      context: context,
      initialDate: _date ?? today,
      firstDate: addDays(today, -OccurrenceValidators.maxDaysAgo),
      lastDate: today,
      helpText: 'Quando aconteceu?',
    );
    if (picked != null) {
      setState(() => _date = picked);
      field.didChange(picked);
    }
  }

  Future<void> _submit() async {
    final valid = _formKey.currentState!.validate();
    if (!valid) {
      showFeedback(context, 'Corrija os campos destacados.');
      return;
    }
    setState(() => _submitting = true);
    final now = ref.read(clockProvider)();
    await ref
        .read(occurrencesProvider.notifier)
        .add(
          Occurrence(
            id: now.microsecondsSinceEpoch.toString(),
            type: _type!,
            sectorId: _sectorId!,
            description: _description.text.trim(),
            severity: _severity,
            occurredOn: dateOnly(_date!),
            createdAt: now,
          ),
        );
    if (!mounted) return;
    _description.clear();
    setState(() {
      _type = null;
      _sectorId = null;
      _date = null;
      _severity = OccurrenceSeverity.medium;
      _submitting = false;
      // Nova chave recria os campos já limpos (mais seguro que reset()).
      _formVersion++;
    });
    showFeedback(
      context,
      'Relato registrado neste aparelho. Obrigado!',
      actionLabel: 'Ver relatos',
      onAction: () => context.goNamed(AppRoutes.occurrences),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final today = ref.watch(clockProvider)();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relatar ocorrência'),
        actions: [
          IconButton(
            tooltip: 'Meus relatos',
            icon: const Icon(Icons.history),
            onPressed: () => context.goNamed(AppRoutes.occurrences),
          ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Card(
              color: theme.colorScheme.primaryContainer,
              child: Padding(
                padding: const EdgeInsets.all(AppSpacing.md),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    ExcludeSemantics(
                      child: Icon(
                        Icons.shield_outlined,
                        color: theme.colorScheme.onPrimaryContainer,
                      ),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    Expanded(
                      child: Text(
                        'Relato anônimo: não pedimos nome, contato nem '
                        'endereço, só o setor. Dois relatos iguais no mesmo '
                        'setor em 3 dias geram um alerta para a equipe.',
                        style: TextStyle(
                          color: theme.colorScheme.onPrimaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            DropdownButtonFormField<OccurrenceType>(
              key: ValueKey('tipo-$_formVersion'),
              initialValue: _type,
              decoration: const InputDecoration(
                labelText: 'Tipo de problema *',
                prefixIcon: Icon(Icons.category_outlined),
              ),
              items: [
                for (final type in OccurrenceType.values)
                  DropdownMenuItem(value: type, child: Text(type.label)),
              ],
              onChanged: (value) => setState(() => _type = value),
              validator: (value) =>
                  OccurrenceValidators.required(value, 'o tipo de problema'),
            ),
            const SizedBox(height: AppSpacing.md),
            DropdownButtonFormField<String>(
              key: ValueKey('setor-$_formVersion'),
              initialValue: _sectorId,
              isExpanded: true,
              decoration: const InputDecoration(
                labelText: 'Setor *',
                prefixIcon: Icon(Icons.place_outlined),
                helperText: 'Só o setor: o endereço exato não é guardado.',
              ),
              items: [
                for (final sector in TerritoryConfig.sectors)
                  DropdownMenuItem(value: sector.id, child: Text(sector.name)),
              ],
              onChanged: (value) => setState(() => _sectorId = value),
              validator: (value) =>
                  OccurrenceValidators.required(value, 'o setor'),
            ),
            const SizedBox(height: AppSpacing.md),
            FormField<DateTime>(
              key: ValueKey('data-$_formVersion'),
              validator: (_) => OccurrenceValidators.date(_date, today),
              builder: (field) => Semantics(
                button: true,
                label:
                    'Data da ocorrência: '
                    '${_date == null ? 'não informada' : Fmt.day(_date!)}',
                child: InkWell(
                  onTap: () => _pickDate(field),
                  borderRadius: BorderRadius.circular(AppSpacing.radius / 2),
                  child: InputDecorator(
                    decoration: InputDecoration(
                      labelText: 'Data *',
                      prefixIcon: const Icon(Icons.event),
                      errorText: field.errorText,
                    ),
                    child: Text(
                      _date == null
                          ? 'Toque para escolher'
                          : Fmt.weekdayDay(_date!),
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            Text('Gravidade', style: theme.textTheme.titleSmall),
            const SizedBox(height: AppSpacing.sm),
            SegmentedButton<OccurrenceSeverity>(
              segments: [
                for (final severity in OccurrenceSeverity.values)
                  ButtonSegment(value: severity, label: Text(severity.label)),
              ],
              selected: {_severity},
              onSelectionChanged: (selection) =>
                  setState(() => _severity = selection.first),
            ),
            const SizedBox(height: AppSpacing.md),
            TextFormField(
              controller: _description,
              maxLines: 4,
              maxLength: OccurrenceValidators.maxDescription,
              textInputAction: TextInputAction.newline,
              decoration: const InputDecoration(
                labelText: 'O que aconteceu? *',
                hintText: 'Ex.: rua alagada perto da escola desde as 7h',
                alignLabelWithHint: true,
                // A mensagem de dados pessoais é longa: não pode ser cortada.
                errorMaxLines: 3,
              ),
              validator: OccurrenceValidators.description,
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton.icon(
              onPressed: _submitting ? null : _submit,
              icon: _submitting
                  ? const SizedBox.square(
                      dimension: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.send),
              label: const Text('Enviar relato'),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text('* Campos obrigatórios', style: theme.textTheme.bodySmall),
            // Espaço para a mensagem flutuante não cobrir o botão.
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}
