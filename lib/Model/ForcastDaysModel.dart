class ForcastDaysModel{
  var _dataTime;
  var _temp;
  var _min;
  var _decription;

  ForcastDaysModel(this._dataTime, this._temp, this._min, this._decription);

  get temp => _temp;

  get dataTime => _dataTime;

  get min => _min;

  get decription => _decription;
}