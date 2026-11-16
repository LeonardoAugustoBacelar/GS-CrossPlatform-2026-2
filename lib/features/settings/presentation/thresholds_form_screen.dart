import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../shared/feedback.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../alerts/domain/alert_thresholds.dart';

/// Formulário de limiares de alerta. Ao salvar, os alertas são recalculados
/// em todas as telas (estado global).
class ThresholdsFormScreen extends ConsumerStatefulWidget {
  const ThresholdsFormScreen({super.key});

  @override
  ConsumerState<ThresholdsFormScreen> createState() =>
      _ThresholdsFormScreenState();
}

class _ThresholdsFormScreenState extends ConsumerState<ThresholdsFormScreen> {
  final _formKey = GlobalKey<FormState>();
  late final Map<ThresholdField, TextEditingController> _controllers;

  static const _groups = {
    'Clima': [
      ThresholdField.heatTemperature,
      ThresholdField.heatDays,
      ThresholdField.rainMm,
      ThresholdField.pm25,
    ],
    'Água e energia': [ThresholdField.waterIncrease, ThresholdField.waterLoss],
    'Serviços públicos': [
      ThresholdField.healthOccupancy,
      ThresholdField.wasteIncrease,
    ],
  };

  @override
  void initState() {
    super.initState();
    final current = ref.read(thresholdsProvider);
    _controllers = {
      for (final field in ThresholdField.values)
        field: TextEditingController(text: field.format(current[field])),
    };
  }

  @override
  void dispose() {
    for (final controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) {
      showFeedback(context, 'Corrija os valores destacados.');
      return;
    }
    await ref
        .read(thresholdsProvider.notifier)
        .save(
          ref.read(thresholdsProvider).copyWith({
            for (final entry in _controllers.entries)
              entry.key: ThresholdField.parse(entry.value.text)!,
          }),
        );
    if (!mounted) return;
    FocusScope.of(context).unfocus();
    showFeedback(context, 'Limiares salvos. Os alertas foram recalculados.');
  }

  Future<void> _restoreDefaults() async {
    await ref.read(thresholdsProvider.notifier).reset();
    for (final entry in _controllers.entries) {
      entry.value.text = entry.key.format(entry.key.defaultValue);
    }
    _formKey.currentState!.validate();
    if (!mounted) return;
    showFeedback(context, 'Valores padrão restaurados.');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Limiares de alerta')),
      body: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: ListView(
          padding: AppSpacing.screen,
          children: [
            Text(
              'Defina a partir de quando cada situação vira alerta. Valores '
              'mais baixos geram mais alertas (e mais falsos alarmes).',
              style: theme.textTheme.bodyLarge,
            ),
            for (final group in _groups.entries) ...[
              const SizedBox(height: AppSpacing.lg),
              Semantics(
                header: true,
                child: Text(group.key, style: theme.textTheme.titleMedium),
              ),
              for (final field in group.value) ...[
                const SizedBox(height: AppSpacing.md),
                TextFormField(
                  controller: _controllers[field],
                  keyboardType: TextInputType.numberWithOptions(
                    decimal: field.decimals > 0,
                  ),
                  inputFormatters: [
                    FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                  ],
                  decoration: InputDecoration(
                    labelText: field.label,
                    suffixText: field.unit,
                    helperText:
                        '${field.help} Entre ${field.format(field.min)} e '
                        '${field.format(field.max)}.',
                    helperMaxLines: 3,
                    errorMaxLines: 2,
                  ),
                  validator: field.validate,
                ),
              ],
            ],
            const SizedBox(height: AppSpacing.lg),
            FilledButton.icon(
              onPressed: _save,
              icon: const Icon(Icons.save_outlined),
              label: const Text('Salvar limiares'),
            ),
            const SizedBox(height: AppSpacing.sm),
            OutlinedButton.icon(
              onPressed: _restoreDefaults,
              icon: const Icon(Icons.restart_alt),
              label: const Text('Restaurar padrões'),
            ),
            // Espaço para a mensagem flutuante não cobrir os botões.
            const SizedBox(height: 96),
          ],
        ),
      ),
    );
  }
}
