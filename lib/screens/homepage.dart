import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/screens/favourites_scr.dart';
import 'package:weather_app/widgets/current_temp.dart';
import 'package:weather_app/widgets/forecast.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/screens/forecast_scr.dart';
import 'package:weather_app/screens/search_scr.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:weather_app/widgets/hourly_forecast.dart';
import 'package:weather_app/widgets/metrics.dart';
import 'package:weather_app/widgets/place_name.dart';
import 'package:weather_app/widgets/weather_details.dart';

class HomePage extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String locality;
  const HomePage({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.locality,
  });

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String API_KEY = "";
  String AQI_API_KEY = "";
  String base_url = "https://api.weatherapi.com/v1";
  String aqi_base_url = "https://api.weatherbit.io/v2.0/forecast/airquality";
  int _bottomNavIndex = 0;
  Position? currentPos;
  String? locality;
  String? temp;
  bool ready = false;
  bool fav = false;
  String? pressure;
  String? humidity;
  String? windSpeed;
  String? tempCondition;
  String? tempCondImg;
  String? feelsLike;
  String? uvIndex;
  String? cloudPercent;
  String? bgImage;
  String? precip;
  String? windGust;
  String? aqi;
  bool forecastReady = false;
  List hourlyForecasts = [];
  List<Widget> dailyForecast = [];
  @override
  void initState() {
    super.initState();
    _askForPermission();
  }

  Future<void> _setFavouriteStatus() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favs = prefs.getString("favourites");
    List _favs = [];
    if (favs != null) {
      _favs = json.decode(favs);
    }
    double? lat, lon;
    if (widget.latitude != -100000 && widget.longitude != -100000) {
      lat = widget.latitude;
      lon = widget.longitude;
    } else {
      lat = currentPos?.latitude;
      lon = currentPos?.longitude;
    }
    for (final place in _favs) {
      if (place['latitude'] == lat && place['longitude'] == lon) {
        setState(() {
          fav = true;
        });
        break;
      }
    }
  }

  Future<void> _getDailyForecast(context) async {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => const Scaffold(
          body: SizedBox(
            width: double.infinity,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
              ],
            ),
          ),
        ),
      ),
    );
    if (dailyForecast.isNotEmpty) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForecastScreen(
            forecasts: dailyForecast,
          ),
        ),
      );
      return;
    }
    double? lat, lon;
    if (widget.latitude != -100000 && widget.longitude != -100000) {
      lat = widget.latitude;
      lon = widget.longitude;
    } else {
      lat = currentPos?.latitude;
      lon = currentPos?.longitude;
    }
    var res = await http.get(Uri.parse(
        "${base_url}/forecast.json?key=${API_KEY}&q=${lat},${lon}&days=8"));
    var jsonRes = jsonDecode(res.body);
    List daily = jsonRes['forecast']['forecastday'];
    daily = daily.sublist(1, daily.length);
    setState(() {
      forecastReady = true;
      dailyForecast = daily.map((data) {
        return DayForecast(
            day: DateFormat("EEEE").format(
                DateTime.fromMillisecondsSinceEpoch(data['date_epoch'] * 1000)),
            maxTemp: data['day']['maxtemp_c'].round(),
            minTemp: data['day']['mintemp_c'].round(),
            image: "https:${data['day']['condition']['icon']}");
      }).toList();
      Navigator.pop(context);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => ForecastScreen(
            forecasts: dailyForecast,
          ),
        ),
      );
    });
  }

  Future<void> _askForPermission() async {
    // final SharedPreferences prefs = await SharedPreferences.getInstance();
    // prefs.setString("favourites", json.encode([]));
    // // print(json.decode(favs!));
    if (widget.longitude != -100000 && widget.latitude != -100000) {
      var res = await http.get(Uri.parse(
          "${base_url}/current.json?key=${API_KEY}&q=${widget.latitude},${widget.longitude}"));
      var jsonResp = jsonDecode(res.body);
      var forecastRes = await http.get(Uri.parse(
          "${base_url}/forecast.json?key=${API_KEY}&q=${widget.latitude},${widget.longitude}"));
      var forecastJsonResp = jsonDecode(forecastRes.body);
      var hourlyJson = forecastJsonResp['forecast']['forecastday'][0]['hour'];
      var hourlyForecastsLocal = hourlyJson.map((data) {
        String hour = data['time'].split(" ")[1].split(":")[0];
        if (int.parse(hour) < 12) {
          hour = "${int.parse(hour)} AM";
        } else if (int.parse(hour) == 12) {
          hour = "$hour PM";
        } else {
          hour = "${int.parse(hour) - 12} PM";
        }
        String temp = data['temp_c'].round().toString();
        return {
          'hour': hour,
          'temp': temp,
          'image': "https:${data['condition']['icon']}"
        };
      }).toList();
      await _getBgImage(jsonResp['current']['condition']['code']);
      setState(() {
        temp = (jsonResp['current']['temp_c']).round().toString();
        pressure = (jsonResp['current']['pressure_mb'] / 10).round().toString();
        humidity = jsonResp['current']['humidity'].toString();
        windSpeed = jsonResp['current']['wind_kph'].round().toString();
        locality = widget.locality;
        feelsLike = jsonResp['current']['feelslike_c'].round().toString();
        tempCondition = jsonResp['current']['condition']['text'];
        tempCondImg = "https:${jsonResp['current']['condition']['icon']}";
        uvIndex = jsonResp['current']['uv'].round().toString();
        cloudPercent = jsonResp['current']['cloud'].round().toString();
        precip = jsonResp['current']['precip_mm'].round().toString();
        windGust = jsonResp['current']['gust_kph'].round().toString();
        hourlyForecasts = hourlyForecastsLocal;
        _setFavouriteStatus();
        ready = true;
      });
      return;
    }

    const permission = Permission.location;
    final status = await permission.request();
    var pos = status.isGranted
        ? await Geolocator.getCurrentPosition()
        : await Geolocator.getLastKnownPosition();
    var res = await http.get(Uri.parse(
        "${base_url}/current.json?key=${API_KEY}&q=${pos?.latitude},${pos?.longitude}"));
    var jsonResp = jsonDecode(res.body);
    var forecastRes = await http.get(Uri.parse(
        "${base_url}/forecast.json?key=${API_KEY}&q=${pos?.latitude},${pos?.longitude}"));
    var forecastJsonResp = jsonDecode(forecastRes.body);
    var hourlyJson = forecastJsonResp['forecast']['forecastday'][0]['hour'];
    var hourlyForecastsLocal = hourlyJson.map((data) {
      String hour = data['time'].split(" ")[1].split(":")[0];
      if (int.parse(hour) < 12) {
        hour = "${int.parse(hour)} AM";
      } else if (int.parse(hour) == 12) {
        hour = "$hour PM";
      } else {
        hour = "${int.parse(hour) - 12} PM";
      }
      String temp = data['temp_c'].round().toString();
      return {
        'hour': hour,
        'temp': temp,
        'image': "https:${data['condition']['icon']}"
      };
    }).toList();
    await _getBgImage(jsonResp['current']['condition']['code']);
    setState(() {
      currentPos = pos;
      temp = (jsonResp['current']['temp_c']).round().toString();
      pressure = (jsonResp['current']['pressure_mb'] / 10).round().toString();
      humidity = jsonResp['current']['humidity'].toString();
      windSpeed = jsonResp['current']['wind_kph'].round().toString();
      locality = jsonResp['location']['name'];
      feelsLike = jsonResp['current']['feelslike_c'].round().toString();
      tempCondition = jsonResp['current']['condition']['text'];
      tempCondImg = "https:${jsonResp['current']['condition']['icon']}";
      uvIndex = jsonResp['current']['uv'].round().toString();
      cloudPercent = jsonResp['current']['cloud'].round().toString();
      precip = jsonResp['current']['precip_mm'].round().toString();
      windGust = jsonResp['current']['gust_kph'].round().toString();
      hourlyForecasts = hourlyForecastsLocal;
      _setFavouriteStatus();
      ready = true;
    });
  }

  Future<int> _getBgImage(int code) async {
    Map codes_map = {
      1000: 'CheckForDayNight',
      1003: 'drizzle.jpg',
      1006: 'clouds.jpg',
      1009: 'clouds.jpg',
      1030: 'mist.jpg',
      1063: 'drizzle.jpg',
      1066: 'snow.jpg',
      1069: 'drizzle.jpg',
      1072: 'drizzle.jpg',
      1087: 'thunderstorm.jpg',
      1114: 'snow.jpg',
      1117: 'snow.jpg',
      1135: 'mist.jpg',
      1147: 'mist.jpg',
      1150: 'drizzle.jpg',
      1153: 'drizzle.jpg',
      1168: 'drizzle.jpg',
      1171: 'drizzle.jpg',
      1180: 'drizzle.jpg',
      1183: 'drizzle.jpg',
      1186: 'rain.jpg',
      1189: 'rain.jpg',
      1192: 'rain.jpg',
      1195: 'rain.jpg',
      1198: 'rain.jpg',
      1201: 'snow.jpg',
      1204: 'snow.jpg',
      1207: 'snow.jpg',
      1210: 'snow.jpg',
      1213: 'snow.jpg',
      1216: 'snow.jpg',
      1219: 'snow.jpg',
      1222: 'snow.jpg',
      1225: 'snow.jpg',
      1237: 'snow.jpg',
      1240: 'rain.jpg',
      1243: 'rain.jpg',
      1246: 'rain.jpg',
      1249: 'snow.jpg',
      1252: 'snow.jpg',
      1255: 'snow.jpg',
      1258: 'snow.jpg',
      1261: 'snow.jpg',
      1264: 'snow.jpg',
      1273: 'snow.jpg',
      1276: 'snow.jpg',
      1279: 'snow.jpg',
      1282: 'snow.jpg'
    };
    String imagePath = "assets/";
    int hour = int.parse(DateFormat("HH").format(DateTime.now()));
    if (code == 1000) {
      if (hour > 5 && hour < 18) {
        imagePath += "day.jpg";
      } else {
        imagePath += "night.jpg";
      }
    } else {
      imagePath += codes_map[code];
    }
    setState(() {
      bgImage = imagePath;
    });
    return 1;
  }

  @override
  Widget build(BuildContext context) {
    return ready
        ? Scaffold(
            bottomNavigationBar: BottomNavigationBar(
              currentIndex: _bottomNavIndex,
              onTap: (value) => setState(() {
                _bottomNavIndex = value;
                if (_bottomNavIndex == 1) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WillPopScope(
                        onWillPop: () async {
                          setState(() {
                            _bottomNavIndex = 0;
                          });
                          return true;
                        },
                        child: const Search(),
                      ),
                    ),
                  );
                } else if (_bottomNavIndex == 2) {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => WillPopScope(
                        onWillPop: () async {
                          setState(() {
                            _bottomNavIndex = 0;
                          });
                          return true;
                        },
                        child: const Favourites(),
                      ),
                    ),
                  );
                }
              }),
              items: [
                BottomNavigationBarItem(
                  label: 'Home',
                  icon: Icon(
                    Icons.home_rounded,
                    color: _bottomNavIndex == 0
                        ? Colors.blue
                        : Colors.grey.shade400,
                  ),
                ),
                BottomNavigationBarItem(
                  label: 'Search',
                  icon: Icon(
                    Icons.search_rounded,
                    color: _bottomNavIndex == 1
                        ? Colors.blue
                        : Colors.grey.shade400,
                  ),
                ),
                BottomNavigationBarItem(
                  label: 'Favourites',
                  icon: Icon(
                    Icons.favorite,
                    color: _bottomNavIndex == 2
                        ? Colors.blue
                        : Colors.grey.shade400,
                  ),
                ),
              ],
            ),
            body: SafeArea(
              child: Stack(
                children: [
                  Image.asset(
                    bgImage!,
                    fit: BoxFit.cover,
                    height: double.infinity,
                  ),
                  Container(
                    decoration: BoxDecoration(
                      color: Colors.black.withOpacity(0.5),
                    ),
                  ),
                  Column(
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 30,
                          vertical: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            PlaceName(label: locality!),
                            IconButton(
                              onPressed: () async {
                                final SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                String? favs = prefs.getString("favourites");
                                List _favs = [];
                                if (favs != null) {
                                  _favs = json.decode(favs);
                                }
                                var label = widget.latitude == -100000
                                    ? locality
                                    : widget.locality;
                                var latitude = widget.latitude == -100000
                                    ? currentPos!.latitude
                                    : widget.latitude;
                                var longitude = widget.latitude == -100000
                                    ? currentPos!.longitude
                                    : widget.longitude;
                                if (fav == false) {
                                  _favs.add({
                                    "label": label,
                                    "latitude": latitude,
                                    "longitude": longitude
                                  });
                                  prefs.setString(
                                    "favourites",
                                    json.encode(_favs),
                                  );
                                } else {
                                  for (final elem in _favs) {
                                    if (_favs[0]['label'] == label &&
                                        _favs[0]['latitude'] == latitude &&
                                        _favs[0]['longitude'] == longitude) {
                                      _favs.remove(elem);
                                      break;
                                    }
                                  }
                                  prefs.setString(
                                    "favourites",
                                    json.encode(_favs),
                                  );
                                }
                                setState(() {
                                  fav = !fav;
                                });
                              },
                              icon: Icon(
                                fav
                                    ? Icons.favorite
                                    : Icons.favorite_border_rounded,
                                color: fav ? Colors.red : Colors.white,
                                size: 26,
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(
                        height: 10,
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          CurrentTemperature(temp: temp!),
                          Text(
                            "Feels like ${feelsLike!}\u00B0 C",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 18,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                          children: [
                            Details(
                              asset: "assets/air-pressure-white.png",
                              value: "${pressure!} hPa",
                            ),
                            Details(
                              asset: "assets/humidity-white.png",
                              value: "${humidity!}%",
                            ),
                            Details(
                              asset: "assets/wind-speed-white.png",
                              value: "${windSpeed!} kmph",
                            ),
                          ],
                        ),
                      ),
                      Metrics(
                        tempCondition: tempCondition!,
                        uvIndex: uvIndex!,
                        precip: precip!,
                        cloudPercent: cloudPercent!,
                        windGust: windGust!,
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                          vertical: 20,
                          horizontal: 30,
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  "Today",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                  ),
                                ),
                                InkWell(
                                  onTap: () => _getDailyForecast(context),
                                  child: const Text(
                                    "Next 7 Days",
                                    style: TextStyle(
                                      color: Colors.white,
                                      decoration: TextDecoration.underline,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(10),
                              height: 115,
                              decoration: BoxDecoration(
                                color: Colors.grey.shade400.withOpacity(0.2),
                                borderRadius: BorderRadius.circular(5),
                              ),
                              child: ListView(
                                physics: const BouncingScrollPhysics(),
                                scrollDirection: Axis.horizontal,
                                children: hourlyForecasts.map((data) {
                                  return HourlyForecast(
                                    hour: data['hour'],
                                    temp: data['temp'],
                                    image: data['image'],
                                  );
                                }).toList(),
                              ),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          )
        : const Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
            ],
          );
  }
}
