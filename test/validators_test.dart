import 'package:flutter_test/flutter_test.dart';
import 'package:mirante/core/domain/time_series.dart';
import 'package:mirante/features/alerts/domain/alert_thresholds.dart';
import 'package:mirante/features/occurrences/domain/occurrence_validators.dart';

import 'support/fixtures.dart';

void main() {
  group('descrição da ocorrência', () {
    test('exige texto mínimo', () {
      expect(OccurrenceValidators.description(''), isNotNull);
      expect(
        OccurrenceValidators.description('muito curto'),
        contains('faltam'),
      );
      expect(
        OccurrenceValidators.description('Água jorrando na calçada desde cedo'),
        isNull,
      );
    });

    test('recusa dados pessoais para manter o relato anônimo', () {
      for (final text in [
        'Me liguem no (11) 98765-4321 para detalhes',
        'Meu CPF é 123.456.789-09, moro aqui',
        'Escrevam para fulano@email.com sobre isso',
      ]) {
        expect(
          OccurrenceValidators.description(text),
          contains('dados pessoais'),
          reason: text,
        );
      }
    });

    test('limita o tamanho máximo', () {
      expect(OccurrenceValidators.description('a' * 401), contains('máximo'));
    });
  });

  test('data da ocorrência: nem futura nem antiga demais', () {
    expect(OccurrenceValidators.date(null, today), isNotNull);
    expect(
      OccurrenceValidators.date(addDays(today, 1), today),
      contains('futuro'),
    );
    expect(
      OccurrenceValidators.date(addDays(today, -31), today),
      contains('30'),
    );
    expect(OccurrenceValidators.date(addDays(today, -3), today), isNull);
  });

  group('limiares de alerta', () {
    test('valida faixa, número e inteiros', () {
      const field = ThresholdField.heatTemperature;
      expect(field.validate(''), 'Informe um valor.');
      expect(field.validate('abc'), 'Use apenas números.');
      expect(field.validate('50'), contains('entre 28 e 42'));
      expect(field.validate('32,5'), isNull);
      expect(ThresholdField.heatDays.validate('2,5'), 'Use um número inteiro.');
    });

    test('serializa e restaura os valores', () {
      final changed = const AlertThresholds().copyWith({
        ThresholdField.rainMm: 50,
      });
      final restored = AlertThresholds.fromJson(changed.toJson());
      expect(restored[ThresholdField.rainMm], 50);
      expect(restored[ThresholdField.pm25], ThresholdField.pm25.defaultValue);
      expect(const AlertThresholds().isDefault, isTrue);
      expect(restored.isDefault, isFalse);
    });
  });
}
