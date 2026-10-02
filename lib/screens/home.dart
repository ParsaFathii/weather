import 'dart:async';
import 'dart:ui';

import 'package:dio/dio.dart' show DioException;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../model/current_city_data_model.dart';
import '../model/forecast_days_model.dart';
import '../services/open_weather_service.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  static const _defaultCity = 'Tehran';
  static const _storedApiKeyPref = 'openweather_api_key';

  final OpenWeatherService _service = OpenWeatherService();
  final TextEditingController _searchController = TextEditingController();
  final StreamController<List<ForecastDaysModel>> _forecastDays =
      StreamController<List<ForecastDaysModel>>();

  /// Null while the stored API key (if any) is being restored at startup.
  Future<CurrentCityDataModel>? _currentWeatherFuture;

  @override
  void initState() {
    super.initState();
    _restoreApiKeyAndLoad();
  }

  /// Restores a user-supplied key saved by the in-app dialog, then loads
  /// the first weather data. Keys passed via `--dart-define` still work:
  /// they are only overridden once the user saves their own key in-app.
  Future<void> _restoreApiKeyAndLoad() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final storedKey = prefs.getString(_storedApiKeyPref);
      if (storedKey != null && storedKey.isNotEmpty) {
        _service.apiKey = storedKey;
      }
    } catch (_) {
      // Storage unavailable (e.g. some web contexts) — fall through and
      // use whatever key was compiled in.
    }
    if (!mounted) return;
    setState(() {
      _currentWeatherFuture = _loadWeather(null);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _forecastDays.close();
    super.dispose();
  }

  /// Loads current conditions, then chains the 7-day forecast
  /// for the returned coordinates.
  Future<CurrentCityDataModel> _loadWeather(String? city) async {
    final data = await _service.fetchCurrentWeather(
      (city == null || city.trim().isEmpty) ? _defaultCity : city.trim(),
    );
    unawaited(_loadForecast(data.lat, data.lon));
    return data;
  }

  Future<void> _loadForecast(double lat, double lon) async {
    try {
      final forecast = await _service.fetchSevenDayForecast(lat, lon);
      if (!mounted) return;
      _forecastDays.add(forecast);
    } on DioException catch (e) {
      _showError('Forecast unavailable (${e.response?.statusCode ?? 'network error'})');
      _forecastDays.add(const []); // stop the loading dots
    } on StateError catch (e) {
      _showError(e.message);
      _forecastDays.add(const []);
    }
  }

  void _searchCity() {
    FocusManager.instance.primaryFocus?.unfocus();
    setState(() {
      _currentWeatherFuture = _loadWeather(_searchController.text);
    });
  }

  void _showError(String? message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message ?? 'Something went wrong')),
    );
  }

  /// Lets the user paste their own free OpenWeatherMap key at runtime —
  /// persisted in [SharedPreferences] so it survives restarts. This is what
  /// makes the release APK usable by anyone, without shipping a key.
  Future<void> _showApiKeyDialog() async {
    final controller = TextEditingController();
    final result = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('OpenWeatherMap API key'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Create a free key at openweathermap.org/api, then paste it here:',
              style: TextStyle(fontSize: 13),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: controller,
              autofocus: true,
              decoration: const InputDecoration(
                hintText: 'your 32-character key',
                border: OutlineInputBorder(),
                isDense: true,
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(dialogContext, controller.text),
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    final key = result?.trim() ?? '';
    if (key.isEmpty) return;

    _service.apiKey = key;
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_storedApiKeyPref, key);
    } catch (_) {
      // Storage unavailable — the key still works for this session.
    }
    if (!mounted) return;
    setState(() {
      _currentWeatherFuture = _loadWeather(null);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Weather App'),
        actions: [
          IconButton(
            tooltip: 'Set OpenWeatherMap API key',
            icon: const Icon(Icons.key),
            onPressed: _showApiKeyDialog,
          ),
        ],
      ),
      body: FutureBuilder<CurrentCityDataModel>(
        future: _currentWeatherFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            final missingKey = snapshot.error is StateError;
            return _ErrorView(
              message: missingKey
                  ? 'No OpenWeatherMap API key set yet.\n'
                      'Grab a free one at openweathermap.org/api and paste it '
                      'with the key button in the top bar.'
                  : snapshot.error.toString(),
              onRetry: () => setState(() {
                _currentWeatherFuture = _loadWeather(_searchController.text);
              }),
              onSetKey: _showApiKeyDialog,
            );
          }
          if (!snapshot.hasData) {
            return const Center(child: JumpingDots());
          }

          final cityData = snapshot.data!;
          return _WeatherContent(
            city: cityData,
            forecastStream: _forecastDays.stream,
            searchController: _searchController,
            onSearch: _searchCity,
          );
        },
      ),
    );
  }
}

class _WeatherContent extends StatelessWidget {
  const _WeatherContent({
    required this.city,
    required this.forecastStream,
    required this.searchController,
    required this.onSearch,
  });

  final CurrentCityDataModel city;
  final Stream<List<ForecastDaysModel>> forecastStream;
  final TextEditingController searchController;
  final VoidCallback onSearch;

  static String _formatTime(int unixSeconds) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      unixSeconds * 1000,
      isUtc: true,
    ).toLocal();
    return DateFormat.jm().format(dateTime);
  }

  @override
  Widget build(BuildContext context) {
    final sunrise = _formatTime(city.sunrise);
    final sunset = _formatTime(city.sunset);

    return Container(
      decoration: const BoxDecoration(
        image: DecorationImage(
          fit: BoxFit.cover,
          image: AssetImage('images/pic_bg.jpg'),
        ),
      ),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
        child: SafeArea(
          child: Center(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(10),
                  child: Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(right: 20),
                        child: ElevatedButton(
                          onPressed: onSearch,
                          child: const Text('Find'),
                        ),
                      ),
                      Expanded(
                        child: TextField(
                          controller: searchController,
                          onSubmitted: (_) => onSearch(),
                          textInputAction: TextInputAction.search,
                          decoration: const InputDecoration(
                            hintText: 'enter your city name',
                            border: UnderlineInputBorder(),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: Text(
                    '${city.cityName}, ${city.country}',
                    style: const TextStyle(color: Colors.white, fontSize: 35),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    city.description,
                    style: const TextStyle(color: Colors.grey, fontSize: 20),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 20),
                  child: _weatherIcon(city.description),
                ),
                Padding(
                  padding: const EdgeInsets.only(top: 10),
                  child: Text(
                    '${city.temp.round()}\u00B0',
                    style: const TextStyle(color: Colors.white, fontSize: 60),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _labeledValue('max', '${city.tempMax.round()}\u00B0'),
                    const _VerticalDivider(),
                    _labeledValue('min', '${city.tempMin.round()}\u00B0'),
                  ],
                ),
                const _HorizontalDivider(),
                SizedBox(
                  height: 100,
                  width: double.infinity,
                  child: Center(
                    child: StreamBuilder<List<ForecastDaysModel>>(
                      stream: forecastStream,
                      builder: (context, snapshot) {
                        if (!snapshot.hasData) {
                          return const JumpingDots(fontSize: 40);
                        }
                        final forecastDays = snapshot.data!;
                        return ListView.builder(
                          shrinkWrap: true,
                          scrollDirection: Axis.horizontal,
                          itemCount: forecastDays.length,
                          itemBuilder: (context, index) =>
                              _ForecastDayItem(forecast: forecastDays[index]),
                        );
                      },
                    ),
                  ),
                ),
                const _HorizontalDivider(),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    _labeledValue('wind speed', '${city.windSpeed} m/s'),
                    const _VerticalDivider(height: 40),
                    _labeledValue('sunrise', sunrise),
                    const _VerticalDivider(height: 40),
                    _labeledValue('sunset', sunset),
                    const _VerticalDivider(height: 40),
                    _labeledValue('humidity', '${city.humidity}%'),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _labeledValue(String label, String value) {
    return Padding(
      padding: const EdgeInsets.all(7),
      child: Column(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white, fontSize: 15)),
          const SizedBox(height: 5),
          Text(value, style: const TextStyle(color: Colors.grey)),
        ],
      ),
    );
  }

  Image _weatherIcon(String description) {
    if (description == 'clear sky') {
      return const Image(image: AssetImage('images/icons8-sun-96.png'));
    } else if (description == 'few clouds') {
      return const Image(
        image: AssetImage('images/icons8-partly-cloudy-day-80.png'),
      );
    } else if (description.contains('clouds')) {
      return const Image(image: AssetImage('images/icons8-clouds-80.png'));
    } else if (description.contains('thunderstorm')) {
      return const Image(image: AssetImage('images/icons8-storm-80.png'));
    } else if (description.contains('drizzle')) {
      return const Image(image: AssetImage('images/icons8-rain-cloud-80.png'));
    } else if (description.contains('rain')) {
      return const Image(image: AssetImage('images/icons8-heavy-rain-80.png'));
    } else if (description.contains('snow')) {
      return const Image(image: AssetImage('images/icons8-snow-80.png'));
    } else {
      return const Image(
        image: AssetImage('images/icons8-windy-weather-80.png'),
      );
    }
  }
}

class _ForecastDayItem extends StatelessWidget {
  const _ForecastDayItem({required this.forecast});

  final ForecastDaysModel forecast;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 70,
      child: Card(
        color: Colors.transparent,
        shadowColor: Colors.transparent,
        child: Column(
          children: [
            Text(
              _formatDayStatic(forecast.dataTime),
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            Expanded(
              child: _iconFor(forecast.description),
            ),
            Text(
              '${forecast.temp.round()}\u00B0',
              style: const TextStyle(color: Colors.white, fontSize: 18),
            ),
          ],
        ),
      ),
    );
  }

  static String _formatDayStatic(int unixSeconds) {
    final dateTime = DateTime.fromMillisecondsSinceEpoch(
      unixSeconds * 1000,
      isUtc: true,
    ).toLocal();
    return DateFormat.MMMd().format(dateTime);
  }

  static Image _iconFor(String description) {
    if (description.contains('clear')) {
      return const Image(image: AssetImage('images/icons8-sun-96.png'));
    } else if (description.contains('cloud')) {
      return const Image(image: AssetImage('images/icons8-clouds-80.png'));
    } else if (description.contains('rain')) {
      return const Image(image: AssetImage('images/icons8-heavy-rain-80.png'));
    } else if (description.contains('snow')) {
      return const Image(image: AssetImage('images/icons8-snow-80.png'));
    } else {
      return const Image(
        image: AssetImage('images/icons8-windy-weather-80.png'),
      );
    }
  }
}

class _VerticalDivider extends StatelessWidget {
  const _VerticalDivider({this.height = 50});

  final double height;

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: height, color: Colors.grey);
  }
}

class _HorizontalDivider extends StatelessWidget {
  const _HorizontalDivider();

  @override
  Widget build(BuildContext context) {
    return const Padding(
      padding: EdgeInsets.all(5),
      child: SizedBox(height: 1, width: double.infinity, child: ColoredBox(color: Colors.grey)),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({
    required this.message,
    required this.onRetry,
    this.onSetKey,
  });

  final String message;
  final VoidCallback onRetry;
  final VoidCallback? onSetKey;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off, size: 64, color: Colors.grey),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
            if (onSetKey != null)
              Padding(
                padding: const EdgeInsets.only(top: 8),
                child: FilledButton.tonalIcon(
                  onPressed: onSetKey,
                  icon: const Icon(Icons.key),
                  label: const Text('Set API key'),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

/// A dependency-free replacement for the abandoned
/// `progress_indicators` package — three pulsing dots.
class JumpingDots extends StatefulWidget {
  const JumpingDots({super.key, this.fontSize = 60, this.color = Colors.white});

  final double fontSize;
  final Color color;

  @override
  State<JumpingDots> createState() => _JumpingDotsState();
}

class _JumpingDotsState extends State<JumpingDots>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 900),
  )..repeat();

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (index) {
        final start = index / 3;
        final curve = CurvedAnimation(
          parent: _controller,
          curve: Interval(start, (start + 0.5).clamp(0.0, 1.0),
              curve: Curves.easeInOut),
        );
        return FadeTransition(
          opacity: Tween<double>(begin: 0.2, end: 1.0).animate(curve),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(
              '\u2022',
              style: TextStyle(
                color: widget.color,
                fontSize: widget.fontSize,
                height: 1,
              ),
            ),
          ),
        );
      }),
    );
  }
}
