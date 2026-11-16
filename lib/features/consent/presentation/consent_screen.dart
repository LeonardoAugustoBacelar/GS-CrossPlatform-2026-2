import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/theme/app_spacing.dart';
import '../../settings/application/settings_controller.dart';

/// Consentimento explícito, exigido antes do primeiro uso.
/// Ao aceitar, o roteador libera o app (veja `redirect` em app_router.dart).
class ConsentScreen extends ConsumerStatefulWidget {
  const ConsentScreen({super.key});

  @override
  ConsumerState<ConsentScreen> createState() => _ConsentScreenState();
}

class _ConsentScreenState extends ConsumerState<ConsentScreen> {
  bool _agreed = false;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(AppSpacing.lg),
          children: [
            Semantics(
              header: true,
              child: Text('Antes de começar', style: textTheme.headlineMedium),
            ),
            const SizedBox(height: AppSpacing.md),
            Text(
              'O Mirante mostra indicadores e alertas sobre o território. '
              'Veja como tratamos os seus dados:',
              style: textTheme.bodyLarge,
            ),
            const SizedBox(height: AppSpacing.lg),
            const _ConsentItem(
              icon: Icons.person_off_outlined,
              text:
                  'Para registrar uma ocorrência não pedimos nome, CPF, e-mail '
                  'nem telefone. A localização é guardada só no nível do bairro.',
            ),
            const _ConsentItem(
              icon: Icons.phone_android_outlined,
              text:
                  'Seus registros e preferências ficam salvos neste aparelho. '
                  'Você pode retirar o consentimento e apagar tudo em Ajustes.',
            ),
            const _ConsentItem(
              icon: Icons.balance_outlined,
              text:
                  'Os alertas são previsões com incerteza. O app não toma '
                  'decisões: quem decide é sempre uma pessoa responsável.',
            ),
            const SizedBox(height: AppSpacing.md),
            CheckboxListTile(
              value: _agreed,
              onChanged: (value) => setState(() => _agreed = value ?? false),
              controlAffinity: ListTileControlAffinity.leading,
              contentPadding: EdgeInsets.zero,
              title: const Text(
                'Li e concordo com o uso dos dados descrito acima.',
              ),
            ),
            const SizedBox(height: AppSpacing.md),
            FilledButton(
              onPressed: _agreed
                  ? () => ref.read(settingsProvider.notifier).giveConsent()
                  : null,
              child: const Text('Continuar'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ConsentItem extends StatelessWidget {
  const _ConsentItem({required this.icon, required this.text});

  final IconData icon;
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: AppSpacing.md),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ExcludeSemantics(
            child: Icon(icon, color: Theme.of(context).colorScheme.primary),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(child: Text(text)),
        ],
      ),
    );
  }
}
