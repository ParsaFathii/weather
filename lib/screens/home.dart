import 'dart:async';
import 'dart:ui';
import 'package:dio/dio.dart';
import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widgets.dart';
import 'package:progress_indicators/progress_indicators.dart';
import 'package:weather/Model/CurrentCityDataModel.dart';
import 'package:intl/intl.dart';
import 'package:weather/Model/ForcastDaysModel.dart';

class Home extends StatefulWidget {
  const Home({super.key});

  @override
  State<Home> createState() => _HomeState();
}

class _HomeState extends State<Home> {
  late StreamController<List<ForcastDaysModel>> StremForcastDays;

  late Future<CurrentCityDataModel> currentWeatherFuture;
  var cityName;
  var lat;
  var lon;
  TextEditingController textEditingController = TextEditingController();

  @override
  void initState() {
    // TODO: implement initState
    super.initState();

    currentWeatherFuture = SendRequestCurrentWeather(cityName);
    StremForcastDays = StreamController<List<ForcastDaysModel>>();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Weather App'),
        elevation: 15,
        actions: <Widget>[
          PopupMenuButton<String>(itemBuilder: (BuildContext context) {
            return {'Setting', 'Profile', 'Logout'}.map((String Choice) {
              return PopupMenuItem(
                value: Choice,
                child: Text(Choice),
              );
            }).toList();
          })
        ],
      ),
      body: FutureBuilder<CurrentCityDataModel>(
        future: currentWeatherFuture,
        builder: (context, snapshot) {
          if (snapshot.hasData) {
            CurrentCityDataModel? cityDataModel = snapshot.data;
            SendRequestSevenDaysForcast(lat, lon);
            final formatter = DateFormat.jm();
            var sunrise = formatter.format(
                new DateTime.fromMicrosecondsSinceEpoch(
                    cityDataModel!.sunrise * 1000,
                    isUtc: true));
            var sunset = formatter.format(
                new DateTime.fromMicrosecondsSinceEpoch(
                    cityDataModel.sunset * 1000,
                    isUtc: true));
            return Container(
              decoration: BoxDecoration(
                image: DecorationImage(
                  fit: BoxFit.cover,
                  image: AssetImage('images/pic_bg.jpg'),
                ),
              ),
              child: BackdropFilter(
                filter: ImageFilter.blur(sigmaX: 10, sigmaY: 10),
                child: Center(
                  child: Column(
                    children: [
                      Padding(
                        padding: EdgeInsets.all(10),
                        child: Row(
                          children: [
                            Padding(
                              padding: EdgeInsets.only(right: 20),
                              child: ElevatedButton(
                                  onPressed: () {
                                    setState(() {
                                      currentWeatherFuture = SendRequestCurrentWeather(textEditingController.text);
                                    });
                                  },
                                  child: Text('Find')),
                            ),
                            Expanded(
                                child: TextField(
                              controller: TextEditingController(),
                              decoration: InputDecoration(
                                  hintText: 'enter you are city name',
                                  hintStyle: TextStyle(color: Colors.white),
                                  border: UnderlineInputBorder()),
                              style: TextStyle(color: Colors.white),
                            ))
                          ],
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 50),
                        child: Text(cityDataModel!.cityName,
                            style:
                                TextStyle(color: Colors.white, fontSize: 35)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 20),
                        child: Text(cityDataModel!.describtion,
                            style: TextStyle(color: Colors.grey, fontSize: 20)),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 30),
                        child: setIconForMain(cityDataModel),
                      ),
                      Padding(
                        padding: EdgeInsets.only(top: 15),
                        child: Text(
                          cityDataModel!.temp.toString() + '\u00B0',
                          style: TextStyle(color: Colors.white, fontSize: 60),
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Column(
                            children: [
                              Text(
                                'max',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 20),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                cityDataModel!.temp_max.toString() + '\u00B0',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              )
                            ],
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Container(
                            width: 1,
                            height: 50,
                            color: Colors.grey,
                          ),
                          SizedBox(
                            width: 10,
                          ),
                          Column(
                            children: [
                              Text(
                                'min',
                                style:
                                    TextStyle(color: Colors.grey, fontSize: 20),
                              ),
                              SizedBox(
                                height: 10,
                              ),
                              Text(
                                cityDataModel!.temp_min.toString() + '\u00B0',
                                style: TextStyle(
                                    color: Colors.white, fontSize: 20),
                              )
                            ],
                          ),
                        ],
                      ),
                      SizedBox(
                        height: 10,
                      ),
                      Padding(
                        padding: EdgeInsets.all(5),
                        child: Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.grey,
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        height: 100,
                        child: Padding(
                          padding: EdgeInsets.only(top: 10),
                          child: Center(
                            child: StreamBuilder<List<ForcastDaysModel>>(
                              stream: StremForcastDays.stream,
                              builder: (context, snapshot) {
                                if (snapshot.hasData) {
                                  List<ForcastDaysModel>? forecastDays =
                                      snapshot.data;
                                  return ListView.builder(
                                      shrinkWrap: true,
                                      scrollDirection: Axis.horizontal,
                                      itemCount: 7,
                                      itemBuilder:
                                          (BuildContext context, int pos) {
                                        return listViewItem(
                                            forecastDays![pos + 1]);
                                      });
                                } else {
                                  return Center(
                                    child: JumpingDotsProgressIndicator(
                                      color: Colors.white,
                                      fontSize: 100,
                                      dotSpacing: 4,
                                    ),
                                  );
                                }
                              },
                            ),
                          ),
                        ),
                      ),
                      Padding(
                        padding: EdgeInsets.all(5),
                        child: Container(
                          height: 1,
                          width: double.infinity,
                          color: Colors.grey,
                        ),
                      ),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Padding(
                            padding: EdgeInsets.only(top: 15),
                            child: Column(
                              children: [
                                Text('wind speed',
                                    style: TextStyle(
                                        color: Colors.white, fontSize: 15)),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(cityDataModel.windSpeed.toString() + 'm/s',
                                    style: TextStyle(color: Colors.grey))
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(7),
                            child: Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 3, top: 15),
                            child: Column(
                              children: [
                                Text(
                                  'sunrise',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  sunrise,
                                  style: TextStyle(color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(7),
                            child: Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 3, top: 15),
                            child: Column(
                              children: [
                                Text(
                                  'sunset',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  sunset,
                                  style: TextStyle(color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.all(7),
                            child: Container(
                              height: 40,
                              width: 1,
                              color: Colors.grey,
                            ),
                          ),
                          Padding(
                            padding: EdgeInsets.only(left: 3, top: 15),
                            child: Column(
                              children: [
                                Text(
                                  'humidity',
                                  style: TextStyle(
                                      color: Colors.white, fontSize: 15),
                                ),
                                SizedBox(
                                  height: 5,
                                ),
                                Text(
                                  cityDataModel!.humidity.toString() +
                                      '%'.toString(),
                                  style: TextStyle(color: Colors.grey),
                                )
                              ],
                            ),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ),
            );
          } else {
            return Center(
              child: JumpingDotsProgressIndicator(
                color: Colors.white,
                fontSize: 100,
                dotSpacing: 4,
              ),
            );
          }
        },
      ),
    );
  }

  Container listViewItem(ForcastDaysModel forecastDay) {
    return Container(
      width: 70,
      height: 50,
      child: Card(
        shadowColor: Colors.transparent,
        color: Colors.transparent,
        child: Column(
          children: [
            Text(
              forecastDay.dataTime,
              style: TextStyle(color: Colors.grey, fontSize: 15),
            ),
            Expanded(child: setIconForMain(forecastDay)),
            Text(forecastDay.temp.round().toString() + '\u00B0',
                style: TextStyle(color: Colors.white, fontSize: 20)),
          ],
        ),
      ),
    );
  }

  Image setIconForMain(model) {
    String description = model.description;

    if (description == 'clear sky') {
      return Image(image: AssetImage('images/icons8-sun-96.png'));
    } else if (description == 'few clouds') {
      return Image(image: AssetImage('images/icons8-partly-cloudy-day-80.png'));
    } else if (description.contains('clouds')) {
      return Image(image: AssetImage('images/icons8-clouds-80.png'));
    } else if (description.contains('thunderstorm')) {
      return Image(image: AssetImage('images/icons8-storm-80.png'));
    } else if (description.contains('drizzle')) {
      return Image(image: AssetImage('images/icons8-clouds-80.png'));
    } else if (description.contains('rain')) {
      return Image(image: AssetImage('images/icons8-heavy-rain-80.png'));
    } else if (description.contains('snow')) {
      return Image(image: AssetImage('images/icons8-snow-80.png'));
    } else {
      return Image(image: AssetImage('icons8-windy-weather-80.png'));
    }
  }

  Future<CurrentCityDataModel> SendRequestCurrentWeather(cityName) async {
    var apiKey = 'f2f757a839a4b06a62fc153e8d9dbf6c';

    var response = await Dio().get(
        'https://api.openweathermap.org/data/2.5/weatherr',
        queryParameters: {'q': cityName, 'appid': apiKey, 'units': 'metric'});

    cityName = response.data["name"];

    var dataModel = CurrentCityDataModel(
        response.data["name"],
        response.data["coord"]["lon"],
        response.data["coord"]["lat"],
        response.data["weather"][0]["main"],
        response.data["weather"][0]["description"],
        response.data["main"]["temp"],
        response.data["main"]["temp_max"],
        response.data["main"]["temp_min"],
        response.data["main"]["pressure"],
        response.data["main"]["humidity"],
        response.data["dt"],
        response.data["sys"]["country"],
        response.data["sys"]["sunrise"],
        response.data["wind"]["speed"],
        response.data["sys"]["sunset"]);

    return dataModel;
  }

  void SendRequestSevenDaysForcast(lon, lat) async {
    List<ForcastDaysModel> list = [];
    var apiKey = 'f2f757a839a4b06a62fc153e8d9dbf6c';

    try {
      var response = await Dio().get(
          'https://api.openweathermap.org/data/3.0/onecall',
          queryParameters: {
            'lat': lat,
            'lon': lon,
            'exclude': 'minutely , hourly',
            'appid': apiKey,
            'unit': 'metric'
          });
      final formatter = DateFormat.MMMd();
      for (int i = 1; i <= 8; i++) {
        var model = response.data['daily'][i];

        var dt = formatter.format(new DateTime.fromMillisecondsSinceEpoch(
            model['dt'] * 1000,
            isUtc: true));

        ForcastDaysModel forcastDaysModel = ForcastDaysModel(
            dt,
            model['temp']['day'],
            model['weather'][0]['maim'],
            model['weather'][0]['describtion']);
        list.add(forcastDaysModel);
      }
      StremForcastDays.add(list);
    } on DioError catch (e) {
      print(e.response?.statusCode);
      print(e.message);
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('there is an'),
      ));
    }
  }
}
