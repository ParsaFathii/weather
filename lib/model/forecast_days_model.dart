/// One day of the daily forecast returned by the OpenWeatherMap
/// One Call API (`/data/3.0/onecall`).
class ForecastDaysModel {
  const ForecastDaysModel({
    required this.dataTime,
    required this.temp,
    required this.main,
    required this.description,
  });

  factory ForecastDaysModel.fromJson(Map<String, dynamic> json) {
    return ForecastDaysModel(
      dataTime: (json['dt'] as num).toInt(),
      temp: (json['temp']['day'] as num).toDouble(),
      main: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
    );
  }

  /// Unix timestamp (seconds) of the forecast day.
  final int dataTime;

  /// Day-time temperature in the requested unit.
  final double temp;

  /// Short weather condition, e.g. "Clear".
  final String main;

  /// Human-readable condition, e.g. "clear sky".
  final String description;
}
