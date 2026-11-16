import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mirante/core/storage/json_cache.dart';
import 'package:mirante/features/climate/data/climate_repository.dart';
import 'package:mirante/features/climate/data/open_meteo_client.dart';
import 'package:mirante/features/climate/domain/climate_snapshot.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'support/fixtures.dart';

const _weather = {
  'daily': {
    'time': ['2026-11-15', '2026-11-16', '2026-11-17'],
    'temperature_2m_max': [27.0, 29.5, 31.2],
    'temperature_2m_min': [18.0, 19.0, 20.0],
    'precipitation_sum': [0.0, 4.2, 12.0],
    'precipitation_probability_max': [null, 60, 85],
  },
};

Map<String, dynamic> get _air => {
  'hourly': {
    'time': [
      for (var h = 0; h < 24; h++) '2026-11-16T${'$h'.padLeft(2, '0')}:00',
    ],
    'pm2_5': [for (var h = 0; h < 24; h++) 10.0 + h],
  },
};

Future<ClimateRepository> _repository(http.Client client) async {
  final prefs = await SharedPreferences.getInstance();
  return ClimateRepository(
    client: OpenMeteoClient(client),
    cache: JsonCache(prefs),
    clock: () => today,
  );
}

http.Response _json(Object body) => http.Response(
  jsonEncode(body),
  200,
  headers: {'content-type': 'application/json'},
);

void main() {
  setUp(() => SharedPreferences.setMockInitialValues({}));

  test('converte a resposta e calcula a média diária de PM2,5', () async {
    final repository = await _repository(
      MockClient(
        (request) async =>
            _json(request.url.host.startsWith('air') ? _air : _weather),
      ),
    );
    final snapshot = await repository.load();

    expect(snapshot.fromCache, isFalse);
    expect(snapshot.days, hasLength(3));
    expect(snapshot.days[2].tempMax, 31.2);
    expect(snapshot.days[1].pm25, closeTo(21.5, 1e-9));
    expect(snapshot.days[0].pm25, isNull, reason: 'dia sem medições');
  });

  test('tenta de novo depois de uma falha passageira', () async {
    var weatherCalls = 0;
    final repository = await _repository(
      MockClient((request) async {
        if (request.url.host.startsWith('air')) return _json(_air);
        weatherCalls++;
        return weatherCalls == 1 ? http.Response('erro', 503) : _json(_weather);
      }),
    );
    final snapshot = await repository.load();

    expect(weatherCalls, 2);
    expect(snapshot.fromCache, isFalse);
  });

  test('sem conexão, usa a última cópia salva', () async {
    final online = await _repository(
      MockClient(
        (request) async =>
            _json(request.url.host.startsWith('air') ? _air : _weather),
      ),
    );
    await online.load();

    final offline = await _repository(
      MockClient((_) async => throw http.ClientException('sem rede')),
    );
    final snapshot = await offline.load();

    expect(snapshot.fromCache, isTrue);
    expect(snapshot.days, hasLength(3));
  });

  test(
    'sem conexão e sem cópia salva, avisa que o clima está indisponível',
    () async {
      final repository = await _repository(
        MockClient((_) async => throw http.ClientException('sem rede')),
      );

      expect(repository.load(), throwsA(isA<ClimateUnavailableException>()));
    },
  );
}
