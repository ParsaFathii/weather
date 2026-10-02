import 'dart:convert';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:weather/model/current_city_data_model.dart';
import 'package:weather/model/forecast_days_model.dart';
import 'package:weather/services/open_weather_service.dart';

const _currentWeatherPayload = {
  'name': 'Tehran',
  'dt': 1759000000,
  'coord': {'lon': 51.39, 'lat': 35.69},
  'weather': [
    {'main': 'Clear', 'description': 'clear sky'},
  ],
  'main': {
    'temp': 27.5,
    'temp_max': 30.1,
    'temp_min': 22.4,
    'pressure': 1012,
    'humidity': 18,
  },
  'wind': {'speed': 3.5},
  'sys': {'country': 'IR', 'sunrise': 1758990000, 'sunset': 1759030000},
};

final _oneCallPayload = {
  'daily': [
    for (var i = 0; i < 8; i++)
      {
        'dt': 1759000000 + i * 86400,
        'temp': {'day': 20.0 + i},
        'weather': [
          {'main': 'Clouds', 'description': 'few clouds'},
        ],
      },
  ],
};

/// A [HttpClientAdapter] that answers with canned JSON and records
/// the last request it received.
class _FakeAdapter implements HttpClientAdapter {
  _FakeAdapter(this.responder);

  final ResponseBody Function(RequestOptions options) responder;
  RequestOptions? lastRequest;

  @override
  void close({bool force = false}) {}

  @override
  Future<ResponseBody> fetch(
    RequestOptions options,
    Stream<Uint8List>? requestStream,
    Future<void>? cancelFuture,
  ) async {
    lastRequest = options;
    return responder(options);
  }
}

ResponseBody _jsonResponse(Map<String, dynamic> body) {
  return ResponseBody.fromString(
    jsonEncode(body),
    200,
    headers: {
      Headers.contentTypeHeader: [Headers.jsonContentType],
    },
  );
}

void main() {
  group('CurrentCityDataModel', () {
    test('parses the /data/2.5/weather payload correctly', () {
      final model = CurrentCityDataModel.fromJson(_currentWeatherPayload);

      expect(model.cityName, 'Tehran');
      expect(model.country, 'IR');
      expect(model.lat, closeTo(35.69, 0.001));
      expect(model.lon, closeTo(51.39, 0.001));
      expect(model.description, 'clear sky');
      expect(model.temp, 27.5);
      expect(model.humidity, 18);
      expect(model.windSpeed, 3.5);
    });
  });

  group('ForecastDaysModel', () {
    test('parses a One Call daily entry correctly', () {
      final model =
          ForecastDaysModel.fromJson(_oneCallPayload['daily']!.first);

      expect(model.dataTime, 1759000000);
      expect(model.temp, 20.0);
      expect(model.main, 'Clouds');
      expect(model.description, 'few clouds');
    });
  });

  group('OpenWeatherService', () {
    test('requests the correct current-weather URL with metric units',
        () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
            (options) => _jsonResponse(_currentWeatherPayload));
      final service = OpenWeatherService(dio: dio, apiKey: 'test-key');

      final model = await service.fetchCurrentWeather('Tehran');

      final request =
          (dio.httpClientAdapter as _FakeAdapter).lastRequest!;
      expect(request.uri.path, '/data/2.5/weather');
      expect(request.queryParameters['q'], 'Tehran');
      expect(request.queryParameters['units'], 'metric');
      expect(request.queryParameters['appid'], 'test-key');
      expect(model.cityName, 'Tehran');
    });

    test('requests the One Call forecast with the right coordinates',
        () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
            (options) => _jsonResponse(_oneCallPayload));
      final service = OpenWeatherService(dio: dio, apiKey: 'test-key');

      final forecast = await service.fetchSevenDayForecast(35.69, 51.39);

      final request =
          (dio.httpClientAdapter as _FakeAdapter).lastRequest!;
      expect(request.uri.path, '/data/3.0/onecall');
      expect(request.queryParameters['lat'], 35.69);
      expect(request.queryParameters['lon'], 51.39);

      // today is skipped, and exactly 7 days are returned
      expect(forecast, hasLength(7));
      expect(forecast.first.dataTime, 1759000000 + 86400);
    });

    test('fails fast with a helpful message when the API key is missing',
        () async {
      final dio = Dio()
        ..httpClientAdapter = _FakeAdapter(
            (options) => _jsonResponse(_currentWeatherPayload));
      final service = OpenWeatherService(dio: dio, apiKey: '');

      await expectLater(
        service.fetchCurrentWeather('Tehran'),
        throwsA(isA<StateError>()),
      );
    });
  });
}
