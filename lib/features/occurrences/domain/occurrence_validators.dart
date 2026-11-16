import '../../../core/domain/time_series.dart';

/// Regras de validação do formulário de ocorrência.
///
/// Funções puras (retornam a mensagem de erro ou `null`), testadas em
/// `test/occurrence_validators_test.dart`.
abstract final class OccurrenceValidators {
  static const minDescription = 15;
  static const maxDescription = 400;
  static const maxDaysAgo = 30;

  static final _cpf = RegExp(r'\b\d{3}\.?\d{3}\.?\d{3}-?\d{2}\b');
  static final _phone = RegExp(r'(\(?\b\d{2}\)?\s?)?\b9?\d{4}[-\s]?\d{4}\b');
  static final _email = RegExp(r'[\w.+-]+@[\w-]+\.[\w.]+');

  static String? required(Object? value, String field) =>
      value == null ? 'Escolha $field.' : null;

  static String? description(String? value) {
    final text = value?.trim() ?? '';
    if (text.isEmpty) return 'Descreva o que aconteceu.';
    if (text.length < minDescription) {
      return 'Escreva pelo menos $minDescription caracteres '
          '(faltam ${minDescription - text.length}).';
    }
    if (text.length > maxDescription) {
      return 'Use no máximo $maxDescription caracteres.';
    }
    if (containsPersonalData(text)) {
      return 'Remova dados pessoais (CPF, telefone ou e-mail): '
          'o relato é anônimo.';
    }
    return null;
  }

  static bool containsPersonalData(String text) =>
      _cpf.hasMatch(text) || _phone.hasMatch(text) || _email.hasMatch(text);

  static String? date(DateTime? value, DateTime today) {
    if (value == null) return 'Informe a data.';
    final diff = daysBetween(value, today);
    if (diff < 0) return 'A data não pode estar no futuro.';
    if (diff > maxDaysAgo) {
      return 'Relate apenas ocorrências dos últimos $maxDaysAgo dias.';
    }
    return null;
  }
}
