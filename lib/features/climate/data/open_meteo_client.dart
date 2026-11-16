import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../core/config/territory_config.dart';

/// Cliente das APIs públicas e gratuitas da Open-Meteo (sem chave).
///
/// - Previsão do tempo: https://open-meteo.com/en/docs
/// - Qualidade do ar (modelo CAMS): https://open-meteo.com/en/docs/air-quality-api
class OpenMeteoClient {
  OpenMeteoClient(this._http);

  final http.Client _http;

  static const _timeout = Duration(seconds: 15);
  static const _attempts = 2;
  static const historyDays = 60;
  static const forecastDays = 7;

  Future<Map<String, dynamic>> fetchWeather() => _get(
    Uri.https('api.open-meteo.com', '/v1/forecast', {
      ..._location,
      'daily':
          'temperature_2m_max,temperature_2m_min,precipitation_sum,'
          'precipitation_probability_max',
      'past_days': '$historyDays',
      'forecast_days': '$forecastDays',
    }),
  );

  Future<Map<String, dynamic>> fetchAirQuality() => _get(
    Uri.https('air-quality-api.open-meteo.com', '/v1/air-quality', {
      ..._location,
      'hourly': 'pm2_5',
      'past_days': '30',
      'forecast_days': '5',
    }),
  );

  static const _location = {
    'latitude': '${TerritoryConfig.latitude}',
    'longitude': '${TerritoryConfig.longitude}',
    'timezone': 'America/Sao_Paulo',
  };

  /// GET com uma nova tentativa: redes móveis falham de forma passageira.
  Future<Map<String, dynamic>> _get(Uri uri) async {
    for (var attempt = 1; ; attempt++) {
      try {
        final response = await _http.get(uri).timeout(_timeout);
        if (response.statusCode != 200) {
          throw http.ClientException('HTTP ${response.statusCode}', uri);
        }
        return jsonDecode(response.body) as Map<String, dynamic>;
      } on Exception {
        if (attempt >= _attempts) rethrow;
        await Future<void>.delayed(const Duration(seconds: 1));
      }
    }
  }
}
