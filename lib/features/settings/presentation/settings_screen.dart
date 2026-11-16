import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/config/territory_config.dart';
import '../../../core/router/app_routes.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../shared/feedback.dart';
import '../../alerts/application/alerts_providers.dart';
import '../../notifications/alert_notifier.dart';
import '../application/settings_controller.dart';

/// Alertas, acessibilidade (tema, contraste, fonte), privacidade e fontes.
class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final settings = ref.watch(settingsProvider);
    final controller = ref.read(settingsProvider.notifier);
    final thresholds = ref.watch(thresholdsProvider);
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Ajustes')),
      body: ListView(
        padding: AppSpacing.screen,
        children: [
          const _SectionTitle('Alertas'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.tune),
            title: const Text('Limiares de alerta'),
            subtitle: Text(
              thresholds.isDefault
                  ? 'Usando os valores padrão'
                  : 'Personalizados pela equipe',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => context.goNamed(AppRoutes.thresholds),
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            secondary: const Icon(Icons.notifications_active_outlined),
            title: const Text('Notificar alertas críticos'),
            subtitle: const Text(
              'Aviso no celular quando surgir um alerta crítico',
            ),
            value: settings.notificationsEnabled,
            onChanged: (value) => _toggleNotifications(context, ref, value),
          ),
          const Divider(height: AppSpacing.xl),
          const _SectionTitle('Aparência e acessibilidade'),
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
            secondary: const Icon(Icons.contrast),
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
          Text(
            'Soma-se ao tamanho de fonte do sistema. Exemplo de texto.',
            style: textTheme.bodyMedium,
          ),
          const Divider(height: AppSpacing.xl),
          const _SectionTitle('Privacidade'),
          ListTile(
            contentPadding: EdgeInsets.zero,
            leading: const Icon(Icons.delete_outline),
            title: const Text('Retirar consentimento e apagar dados'),
            subtitle: const Text(
              'Remove relatos, decisões e preferências deste aparelho',
            ),
            onTap: () => _confirmRevoke(context, controller),
          ),
          const Divider(height: AppSpacing.xl),
          const _SectionTitle('Sobre os dados'),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.public),
            title: Text('Clima e qualidade do ar: dados reais'),
            subtitle: Text(
              'Open-Meteo (previsão do tempo e modelo CAMS), dados abertos '
              'e gratuitos.',
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.science_outlined),
            title: Text('Água, energia e serviços: dados sintéticos'),
            subtitle: Text(
              'Gerados por uma API simulada para fins acadêmicos. Mostram o '
              'método, não a situação real do território.',
            ),
          ),
          const ListTile(
            contentPadding: EdgeInsets.zero,
            leading: Icon(Icons.map_outlined),
            title: Text('Mapa'),
            subtitle: Text('© colaboradores do OpenStreetMap'),
          ),
          const SizedBox(height: AppSpacing.md),
          Text(
            'Mirante · ${TerritoryConfig.name} · Projeto acadêmico FIAP, '
            'Global Solution 2026.2',
            style: textTheme.bodySmall,
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: AppSpacing.lg),
        ],
      ),
    );
  }

  Future<void> _toggleNotifications(
    BuildContext context,
    WidgetRef ref,
    bool enable,
  ) async {
    final controller = ref.read(settingsProvider.notifier);
    if (!enable) {
      await controller.setNotificationsEnabled(false);
      return;
    }
    final granted = await ref.read(alertNotifierProvider).requestPermission();
    await controller.setNotificationsEnabled(granted);
    if (granted) {
      final report = ref.read(alertReportProvider).value;
      if (report != null) {
        await ref.read(alertNotifierProvider).notifyCritical(report.alerts);
      }
    }
    if (!context.mounted) return;
    showFeedback(
      context,
      granted
          ? 'Notificações ativadas para alertas críticos.'
          : 'Permissão negada. Ative as notificações nas configurações do '
                'celular.',
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
