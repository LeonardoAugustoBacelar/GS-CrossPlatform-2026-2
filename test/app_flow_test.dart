import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'support/fixtures.dart';
import 'support/test_app.dart';

void main() {
  group('consentimento', () {
    testWidgets('sem consentimento, o app abre na tela de consentimento', (
      tester,
    ) async {
      await pumpMirante(tester, consent: false);

      expect(find.text('Antes de começar'), findsOneWidget);
      final continuar = find.widgetWithText(FilledButton, 'Continuar');
      expect(tester.widget<FilledButton>(continuar).onPressed, isNull);
    });

    testWidgets('aceitar libera a visão geral do território', (tester) async {
      await pumpMirante(tester, consent: false);

      await tester.tap(find.byType(CheckboxListTile));
      await tester.pump();
      await tester.ensureVisible(find.text('Continuar'));
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();

      expect(find.text("M'Boi Mirim"), findsOneWidget);
    });
  });

  testWidgets('visão geral mostra alertas, aviso humano e benefício social', (
    tester,
  ) async {
    await pumpMirante(tester);

    expect(find.textContaining('não substituem'), findsOneWidget);
    expect(find.text('Alertas ativos'), findsOneWidget);
    expect(find.textContaining('Perdas de água fora do normal'), findsWidgets);
    await scrollTo(tester, find.text('Benefício social'));
    expect(find.text('Moradores em áreas com alerta'), findsOneWidget);
  });

  testWidgets('fluxo: visão geral → dashboard → indicador', (tester) async {
    await pumpMirante(tester);

    await scrollTo(tester, find.text('Água e energia'));
    await tester.tap(find.text('Água e energia'));
    await tester.pumpAndSettle();
    expect(find.text('Consumo de água por habitante'), findsOneWidget);

    await tester.ensureVisible(find.text('Ver detalhes').first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Ver detalhes').first);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Como a previsão é feita'));
    expect(find.text('R² (ajuste)'), findsOneWidget);
  });

  testWidgets('detalhe do alerta traz evidência, confiança e limitações', (
    tester,
  ) async {
    await pumpMirante(tester);

    await tester.tap(find.text('Alertas').last);
    await tester.pumpAndSettle();
    await tester.tap(find.textContaining('Perdas de água fora do normal'));
    await tester.pumpAndSettle();

    await scrollTo(tester, find.text('Por que este alerta?'));
    await scrollTo(tester, find.text('Nível de confiança'));
    await scrollTo(tester, find.text('Limitações e quando não confiar'));
    await scrollTo(tester, find.text('Registrar decisão'));
    expect(find.textContaining('não executa nenhuma ação'), findsOneWidget);
  });

  testWidgets('sem conexão e sem cache: clima mostra erro, resto funciona', (
    tester,
  ) async {
    await pumpMirante(tester, offline: true);

    await tester.tap(find.text('Alertas').last);
    await tester.pumpAndSettle();
    expect(find.textContaining('Clima indisponível'), findsOneWidget);
    expect(
      find.textContaining('Perdas de água fora do normal'),
      findsOneWidget,
    );

    await tester.tap(find.text('Início'));
    await tester.pumpAndSettle();
    await scrollTo(tester, find.text('Clima local'));
    await tester.tap(find.text('Clima local'));
    await tester.pumpAndSettle();
    expect(find.text('Tentar de novo'), findsOneWidget);
  });

  testWidgets('limiar mais baixo gera alerta de calor', (tester) async {
    await pumpMirante(
      tester,
      climate: climateFixture(forecastMax: [29, 30, 31, 27, 27, 27, 27]),
    );
    expect(find.textContaining('Onda de calor'), findsNothing);

    await tester.tap(find.text('Ajustes'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Limiares de alerta'));
    await tester.pumpAndSettle();

    final heatField = find.widgetWithText(
      TextFormField,
      'Temperatura máxima (onda de calor)',
    );
    await tester.enterText(heatField, '50');
    await tester.pump();
    expect(find.textContaining('entre 28 e 42'), findsOneWidget);

    await tester.enterText(heatField, '29,5');
    await scrollTo(tester, find.text('Salvar limiares'));
    await tester.tap(find.text('Salvar limiares'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Alertas').last);
    await tester.pumpAndSettle();
    await scrollTo(tester, find.textContaining('Onda de calor prevista'));
  });

  group('formulário de ocorrência', () {
    testWidgets('mostra erros ao enviar vazio', (tester) async {
      await pumpMirante(tester);
      await tester.tap(find.text('Relatar'));
      await tester.pumpAndSettle();

      await scrollTo(tester, find.text('Enviar relato'));
      await tester.tap(find.text('Enviar relato'));
      await tester.pumpAndSettle();

      expect(find.text('Descreva o que aconteceu.'), findsOneWidget);
      await scrollTo(tester, find.text('Escolha o tipo de problema.'));
      expect(find.text('Escolha o setor.'), findsOneWidget);
    });

    testWidgets('recusa telefone na descrição (anonimato)', (tester) async {
      await pumpMirante(tester);
      await tester.tap(find.text('Relatar'));
      await tester.pumpAndSettle();

      await tester.enterText(
        find.widgetWithText(TextFormField, 'O que aconteceu? *'),
        'Água jorrando na calçada, liguem 11 98765-4321',
      );
      await scrollTo(tester, find.text('Enviar relato'));
      await tester.tap(find.text('Enviar relato'));
      await tester.pumpAndSettle();

      expect(find.textContaining('Remova dados pessoais'), findsOneWidget);
    });
  });

  for (final size in const [Size(360, 640), Size(800, 1280)]) {
    testWidgets('telas sem estouro de layout em ${size.width.toInt()}px', (
      tester,
    ) async {
      await pumpMirante(tester, size: size);
      for (final area in [
        'Clima local',
        'Água e energia',
        'Serviços públicos',
      ]) {
        await tester.tap(find.text('Início'));
        await tester.pumpAndSettle();
        await scrollTo(tester, find.text(area));
        await tester.tap(find.text(area));
        await tester.pumpAndSettle();
        expect(tester.takeException(), isNull);
      }
    });
  }
}
