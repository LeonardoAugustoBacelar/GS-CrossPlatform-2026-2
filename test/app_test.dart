import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mirante/app.dart';
import 'package:mirante/core/storage/preferences_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

Future<void> _pumpApp(
  WidgetTester tester, {
  Map<String, Object> preferences = const {},
}) async {
  SharedPreferences.setMockInitialValues(preferences);
  final instance = await SharedPreferences.getInstance();
  await tester.pumpWidget(
    ProviderScope(
      overrides: [sharedPreferencesProvider.overrideWithValue(instance)],
      child: const MiranteApp(),
    ),
  );
  await tester.pumpAndSettle();
}

void main() {
  testWidgets('sem consentimento, o app abre na tela de consentimento', (
    tester,
  ) async {
    await _pumpApp(tester);

    expect(find.text('Antes de começar'), findsOneWidget);
    final continuar = find.widgetWithText(FilledButton, 'Continuar');
    expect(tester.widget<FilledButton>(continuar).onPressed, isNull);
  });

  testWidgets('aceitar o consentimento libera a visão geral', (tester) async {
    await _pumpApp(tester);

    await tester.tap(find.byType(CheckboxListTile));
    await tester.pump();
    await tester.ensureVisible(find.text('Continuar'));
    await tester.tap(find.text('Continuar'));
    await tester.pumpAndSettle();

    expect(find.text('Visão geral'), findsOneWidget);
  });

  testWidgets('com consentimento salvo, abre direto na visão geral', (
    tester,
  ) async {
    await _pumpApp(tester, preferences: {'settings.consent_given': true});

    expect(find.text('Visão geral'), findsOneWidget);
  });
}
