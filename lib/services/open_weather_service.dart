import 'package:dio/dio.dart';

import '../model/current_city_data_model.dart';
import '../model/forecast_days_model.dart';

/// The OpenWeatherMap API key is provided at **run time** via
/// `--dart-define`, so no secret ever lives in source control:
///
/// ```bash
/// flutter run --dart-define=OPENWEATHER_API_KEY=<your_key>
/// ```
const String _openWeatherApiKey = String.fromEnvironment('OPENWEATHER_API_KEY');

/// Thin client around the OpenWeatherMap REST endpoints.
class OpenWeatherService {
  /// [apiKey] is injectable for tests; production reads it from
  /// `--dart-define=OPENWEATHER_API_KEY`.
  OpenWeatherService({Dio? dio, String? apiKey})
      : _dio = dio ?? Dio(),
        _apiKey = apiKey ?? _openWeatherApiKey;

  final Dio _dio;
  final String _apiKey;

  static const String _currentWeatherUrl =
      'https://api.openweathermap.org/data/2.5/weather';
  static const String _oneCallUrl =
      'https://api.openweathermap.org/data/3.0/onecall';

  /// Current conditions for [cityName] (defaults to geolocation-free
  /// lookup by city name).
  Future<CurrentCityDataModel> fetchCurrentWeather(String? cityName) async {
    _ensureApiKey();
    final response = await _dio.get<dynamic>(
      _currentWeatherUrl,
      queryParameters: <String, dynamic>{
        if (cityName != null && cityName.isNotEmpty) 'q': cityName,
        'appid': _apiKey,
        'units': 'metric',
      },
    );
    return CurrentCityDataModel.fromJson(
      Map<String, dynamic>.from(response.data as Map),
    );
  }

  /// The next 7 days (today excluded) for the given coordinates.
  Future<List<ForecastDaysModel>> fetchSevenDayForecast(
    double lat,
    double lon,
  ) async {
    _ensureApiKey();
    final response = await _dio.get<dynamic>(
      _oneCallUrl,
      queryParameters: <String, dynamic>{
        'lat': lat,
        'lon': lon,
        'exclude': 'minutely,hourly',
        'appid': _apiKey,
        'units': 'metric',
      },
    );
    final daily =
        (response.data as Map<String, dynamic>)['daily'] as List<dynamic>;
    return daily
        .skip(1) // today is already shown as "current"
        .take(7)
        .map((day) => ForecastDaysModel.fromJson(
              Map<String, dynamic>.from(day as Map),
            ))
        .toList();
  }

  void _ensureApiKey() {
    if (_apiKey.isEmpty) {
      throw StateError(
        'OPENWEATHER_API_KEY is missing. Start the app with '
        '--dart-define=OPENWEATHER_API_KEY=<your key>',
      );
    }
  }
}
