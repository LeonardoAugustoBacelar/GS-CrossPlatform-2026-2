import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../application/settings_controller.dart';

/// Acessibilidade (tema, alto contraste, tamanho da fonte) e privacidade.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const _SectionTitle('Aparência'),
          const SizedBox(height: AppSpacing.sm),
          SegmentedButton<ThemeMode>(
            segments: const [
              ButtonSegment(value: ThemeMode.system, label: Text('Sistema')),
              ButtonSegment(value: ThemeMode.light, label: Text('Claro')),
              ButtonSegment(value: ThemeMode.dark, label: Text('Escuro')),
            ],
            selected: {settings.themeMode},
            onSelectionChanged: (selection) =>
                controller.setThemeMode(selection.first),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('Alto contraste'),
            subtitle: const Text('Reforça cores e bordas'),
            value: settings.highContrast,
            onChanged: controller.setHighContrast,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text('Tamanho do texto', style: textTheme.titleSmall),
          Slider(
            value: settings.textScale,
            min: 1.0,
            max: 1.6,
            divisions: 3,
            label: '${(settings.textScale * 100).round()}%',
            semanticFormatterCallback: (value) =>
                'Tamanho do texto ${(value * 100).round()} por cento',
            onChanged: controller.setTextScale,
          ),
          const Divider(height: AppSpacing.xl),
          const _SectionTitle('Privacidade'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline),
            title: const Text('Retirar consentimento e apagar dados'),
            subtitle: const Text(
              'Remove ocorrências e preferências guardadas neste aparelho',
            ),
            onTap: () => _confirmRevoke(context, controller),
          ),
        ],
      ),
    );
  }

  Future<void> _confirmRevoke(
    BuildContext context,
    SettingsController controller,
  ) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Apagar seus dados?'),
        content: const Text(
          'Tudo o que foi salvo neste aparelho será removido e o app voltará '
          'para a tela de consentimento.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Apagar'),
          ),
        ],
      ),
    );
    if (confirmed ?? false) await controller.revokeConsentAndDeleteData();
  }
}

class _SectionTitle extends StatelessWidget {
  const _SectionTitle(this.text);

  final String text;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      header: true,
      child: Text(
        text,
        style: Theme.of(context).textTheme.titleMedium
            ?.copyWith(color: Theme.of(context).colorScheme.primary),
      ),
    );
  }
}
