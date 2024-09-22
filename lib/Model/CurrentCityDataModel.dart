class CurrentCityDataModel {
  String _cityName;
  var _lon;
  var _lat;
  String _main;
  String _describtion;
  var _temp;
  var _temp_max;
  var _temp_min;
  var _pressure;
  var _humidity;
  var _dataTime;
  String _country;
  var _sunrise;
  var _sunset;
  var _windSpeed;


  CurrentCityDataModel(
      this._cityName,
      this._lon,
      this._lat,
      this._main,
      this._describtion,
      this._temp,
      this._temp_max,
      this._temp_min,
      this._pressure,
      this._humidity,
      this._dataTime,
      this._country,
      this._sunrise,
      this._windSpeed,
      this._sunset);

  get sunset => _sunset;

  get sunrise => _sunrise;

  String get country => _country;

  get dataTime => _dataTime;

  get humidity => _humidity;

  get pressure => _pressure;

  get temp_min => _temp_min;

  get temp_max => _temp_max;

  get temp => _temp;

  String get describtion => _describtion;

  String get main => _main;

  get lat => _lat;

  get lon => _lon;

  String get cityName => _cityName;

  get windSpeed => _windSpeed;
}
