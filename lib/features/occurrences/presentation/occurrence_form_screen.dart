import 'package:flutter/material.dart';

import '../../../shared/widgets/state_views.dart';

/// Formulário de ocorrência do cidadão (critério 6).
///
/// TODO: campos com validação e mensagens de erro claras, sem dados pessoais
/// (só bairro), e gravação local para funcionar sem conexão.
class OccurrenceFormScreen extends StatelessWidget {
  const OccurrenceFormScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Relatar ocorrência')),
      body: const EmptyView(
        icon: Icons.edit_note,
        message: 'Formulário de ocorrência em construção.',
      ),
    );
  }
}
