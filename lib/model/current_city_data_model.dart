/// Current-weather payload returned by the OpenWeatherMap
/// "Current Weather API" (`/data/2.5/weather`).
class CurrentCityDataModel {
  const CurrentCityDataModel({
    required this.cityName,
    required this.country,
    required this.lon,
    required this.lat,
    required this.main,
    required this.description,
    required this.temp,
    required this.tempMax,
    required this.tempMin,
    required this.pressure,
    required this.humidity,
    required this.dataTime,
    required this.sunrise,
    required this.sunset,
    required this.windSpeed,
  });

  factory CurrentCityDataModel.fromJson(Map<String, dynamic> json) {
    return CurrentCityDataModel(
      cityName: json['name'] as String,
      country: json['sys']['country'] as String,
      lon: (json['coord']['lon'] as num).toDouble(),
      lat: (json['coord']['lat'] as num).toDouble(),
      main: json['weather'][0]['main'] as String,
      description: json['weather'][0]['description'] as String,
      temp: (json['main']['temp'] as num).toDouble(),
      tempMax: (json['main']['temp_max'] as num).toDouble(),
      tempMin: (json['main']['temp_min'] as num).toDouble(),
      pressure: (json['main']['pressure'] as num).toInt(),
      humidity: (json['main']['humidity'] as num).toInt(),
      dataTime: (json['dt'] as num).toInt(),
      sunrise: (json['sys']['sunrise'] as num).toInt(),
      sunset: (json['sys']['sunset'] as num).toInt(),
      windSpeed: (json['wind']['speed'] as num).toDouble(),
    );
  }

  final String cityName;
  final String country;
  final double lon;
  final double lat;
  final String main;
  final String description;
  final double temp;
  final double tempMax;
  final double tempMin;
  final int pressure;
  final int humidity;
  final int dataTime;
  final int sunrise;
  final int sunset;
  final double windSpeed;
}
