import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:http/http.dart' as http;

/// Cliente HTTP compartilhado. Nos testes é substituído por um falso.
final httpClientProvider = Provider<http.Client>((ref) {
  final client = http.Client();
  ref.onDispose(client.close);
  return client;
});

/// Relógio do app. Nos testes é fixado para os resultados serem repetíveis.
final clockProvider = Provider<DateTime Function()>((ref) => DateTime.now);
