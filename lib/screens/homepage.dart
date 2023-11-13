import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/widgets/forecast.dart';
import 'package:intl/intl.dart';
import 'package:weather_app/screens/forecast_scr.dart';
import 'package:weather_app/screens/search_scr.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    var res = await http.get(Uri.parse(
        "${base_url}/forecast.json?key=${API_KEY}&q=${currentPos?.latitude},${currentPos?.longitude}&days=8"));
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
            image: "https:" + data['day']['condition']['icon']);
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
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favs = prefs.getString("favourites");
    print(json.decode(favs!));
    if (widget.longitude != -100000 && widget.latitude != -100000) {
      setState(() {
        http
            .get(Uri.parse(
                "${base_url}/current.json?key=${API_KEY}&q=${widget.latitude},${widget.longitude}"))
            .then((res) {
          setState(() {
            var jsonResp = jsonDecode(res.body);
            temp = (jsonResp['current']['temp_c']).round().toString();
            pressure =
                (jsonResp['current']['pressure_mb'] / 10).round().toString();
            humidity = jsonResp['current']['humidity'].toString();
            windSpeed = jsonResp['current']['wind_kph'].round().toString();
            locality = widget.locality;
            feelsLike = jsonResp['current']['feelslike_c'].round().toString();
            tempCondition = jsonResp['current']['condition']['text'];
            tempCondImg = "https:" + jsonResp['current']['condition']['icon'];
            uvIndex = jsonResp['current']['uv'].round().toString();
            cloudPercent = jsonResp['current']['cloud'].round().toString();
            precip = jsonResp['current']['precip_mm'].round().toString();
            windGust = jsonResp['current']['gust_kph'].round().toString();
            http
                .get(Uri.parse(
                    "${base_url}/forecast.json?key=${API_KEY}&q=${widget.latitude},${widget.longitude}"))
                .then((res) {
              setState(() {
                var hourlyJson =
                    jsonDecode(res.body)['forecast']['forecastday'][0]['hour'];
                hourlyForecasts = hourlyJson.map((data) {
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
              });
            });
            _getBgImage(jsonResp['current']['condition']['code']).then((res) {
              ready = true;
            });
          });
        });
      });
      return;
    }
    const permission = Permission.location;
    final status = await permission.request();
    if (status.isGranted) {
      Geolocator.getCurrentPosition().then((pos) {
        setState(() {
          currentPos = pos;
          http
              .get(Uri.parse(
                  "${base_url}/current.json?key=${API_KEY}&q=${currentPos?.latitude},${currentPos?.longitude}"))
              .then((res) {
            setState(() {
              var jsonResp = jsonDecode(res.body);
              temp = (jsonResp['current']['temp_c']).round().toString();
              pressure =
                  (jsonResp['current']['pressure_mb'] / 10).round().toString();
              humidity = jsonResp['current']['humidity'].toString();
              windSpeed = jsonResp['current']['wind_kph'].round().toString();
              locality = jsonResp['location']['name'];
              feelsLike = jsonResp['current']['feelslike_c'].round().toString();
              tempCondition = jsonResp['current']['condition']['text'];
              tempCondImg = "https:" + jsonResp['current']['condition']['icon'];
              uvIndex = jsonResp['current']['uv'].round().toString();
              cloudPercent = jsonResp['current']['cloud'].round().toString();
              precip = jsonResp['current']['precip_mm'].round().toString();
              windGust = jsonResp['current']['gust_kph'].round().toString();
              http
                  .get(Uri.parse(
                      "${base_url}/forecast.json?key=${API_KEY}&q=${currentPos?.latitude},${currentPos?.longitude}"))
                  .then((res) {
                setState(() {
                  var hourlyJson = jsonDecode(res.body)['forecast']
                      ['forecastday'][0]['hour'];
                  hourlyForecasts = hourlyJson.map((data) {
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
                });
              });
              _getBgImage(jsonResp['current']['condition']['code']).then((res) {
                ready = true;
              });
            });
          });
        });
      });
    } else {
      Geolocator.getLastKnownPosition().then((pos) {
        setState(() {
          currentPos = pos;
          http
              .get(Uri.parse(
                  "${base_url}/current.json?key=${API_KEY}&q=${currentPos?.latitude},${currentPos?.longitude}"))
              .then((res) {
            setState(() {
              var jsonResp = jsonDecode(res.body);
              temp = (jsonResp['current']['temp_c']).round().toString();
              pressure =
                  (jsonResp['current']['pressure_mb'] / 0.1).round().toString();
              humidity = jsonResp['current']['humidity'].toString();
              locality = jsonResp['location']['name'];
              windSpeed = jsonResp['current']['wind_kph'].round().toString();
              feelsLike = jsonResp['current']['feelslike_c'].round().toString();
              tempCondition = jsonResp['current']['condition']['text'];
              tempCondImg = "https:" + jsonResp['current']['condition']['icon'];
              uvIndex = jsonResp['current']['uv'].round().toString();
              cloudPercent = jsonResp['current']['cloud'].round().toString();
              precip = jsonResp['current']['precip_mm'].round().toString();
              windGust = jsonResp['current']['gust_kph'].round().toString();
              http
                  .get(Uri.parse(
                      "${base_url}/forecast.json?key=${API_KEY}&q=${currentPos?.latitude},${currentPos?.longitude}"))
                  .then((res) {
                setState(() {
                  var hourlyJson = jsonDecode(res.body)['forecast']
                      ['forecastday'][0]['hour'];
                  hourlyForecasts = hourlyJson.map((data) {
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
                });
              });
              _getBgImage(jsonResp['current']['condition']['code']).then((res) {
                ready = true;
              });
            });
          });
        });
      });
    }
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
                }
              }),
              items: [
                BottomNavigationBarItem(
                  label: 'Home',
                  icon: Icon(
                    Icons.home_rounded,
                    color: _bottomNavIndex == 0
                        ? Colors.white
                        : Colors.grey.shade400,
                  ),
                ),
                BottomNavigationBarItem(
                  label: 'Search',
                  icon: Icon(
                    Icons.search_rounded,
                    color: _bottomNavIndex == 1
                        ? Colors.white
                        : Colors.grey.shade400,
                  ),
                ),
                BottomNavigationBarItem(
                  label: 'Favourites',
                  icon: Icon(
                    Icons.favorite,
                    color: _bottomNavIndex == 2
                        ? Colors.white
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
                            Row(
                              children: [
                                const Icon(
                                  Icons.location_on_outlined,
                                  color: Colors.white,
                                  size: 30,
                                ),
                                const SizedBox(
                                  width: 5,
                                ),
                                Text(
                                  locality!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                            IconButton(
                              onPressed: () async {
                                final SharedPreferences prefs =
                                    await SharedPreferences.getInstance();
                                String? favs = prefs.getString("favourites");
                                List _favs = [];
                                if (favs != null) {
                                  _favs = json.decode(favs);
                                }
                                if (fav == false) {
                                  if (widget.latitude == -100000) {
                                    _favs.add({
                                      "label": locality,
                                      "latitude": currentPos!.latitude,
                                      "longitude": currentPos!.longitude
                                    });
                                    prefs.setString(
                                      "favourites",
                                      json.encode(_favs),
                                    );
                                    print(json.decode(
                                        prefs.getString("favourites")!));
                                  } else {
                                    _favs.add({
                                      "label": widget.locality,
                                      "latitude": widget.latitude,
                                      "longitude": widget.longitude
                                    });
                                    prefs.setString(
                                      "favourites",
                                      json.encode(_favs),
                                    );
                                    print(json.decode(
                                        prefs.getString("favourites")!));
                                  }
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
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  text: temp!,
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 100,
                                  ),
                                  children: const [
                                    TextSpan(
                                      text: "\u00B0",
                                      style: TextStyle(
                                        // fontSize: 20,
                                        color: Colors.white,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
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
                            Row(
                              children: [
                                Image.asset(
                                  "assets/air-pressure-white.png",
                                  width: 25,
                                  height: 25,
                                ),
                                const SizedBox(
                                  width: 7,
                                ),
                                Text(
                                  "${pressure!} hPa",
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Image.asset(
                                  "assets/humidity-white.png",
                                  width: 25,
                                  height: 25,
                                ),
                                const SizedBox(
                                  width: 7,
                                ),
                                Text(
                                  "${humidity!}%",
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                            Row(
                              children: [
                                Image.asset(
                                  "assets/wind-speed-white.png",
                                  width: 25,
                                  height: 25,
                                ),
                                const SizedBox(
                                  width: 7,
                                ),
                                Text(
                                  "${windSpeed!} kmph",
                                  style: const TextStyle(
                                    color: Colors.white,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.symmetric(
                          vertical: 10,
                          horizontal: 20,
                        ),
                        margin: const EdgeInsets.symmetric(
                          vertical: 0,
                          horizontal: 30,
                        ),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(5),
                          color: Colors.grey.shade400.withOpacity(0.2),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Metrics",
                              style: TextStyle(
                                color: Colors.white,
                                letterSpacing: 1,
                                fontSize: 16,
                              ),
                            ),
                            const SizedBox(
                              height: 10,
                            ),
                            Column(
                              children: [
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "CONDITION",
                                          style: TextStyle(
                                            color: Color.fromRGBO(
                                                200, 200, 200, 1),
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          tempCondition!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "ULTRAVIOLET",
                                          style: TextStyle(
                                            color: Color.fromRGBO(
                                                200, 200, 200, 1),
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          uvIndex!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "PRECIPITATION",
                                          style: TextStyle(
                                            color: Color.fromRGBO(
                                                200, 200, 200, 1),
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${precip!} mm",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      mainAxisAlignment:
                                          MainAxisAlignment.start,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "CLOUDINESS",
                                          style: TextStyle(
                                            color: Color.fromRGBO(
                                                200, 200, 200, 1),
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${cloudPercent!}%",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                                const SizedBox(
                                  height: 10,
                                ),
                                Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: [
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "WIND GUST",
                                          style: TextStyle(
                                            color: Color.fromRGBO(
                                                200, 200, 200, 1),
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          "${windGust!} kmph",
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    ),
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        const Text(
                                          "AIR QUALITY",
                                          style: TextStyle(
                                            color: Color.fromRGBO(
                                                200, 200, 200, 1),
                                            letterSpacing: 2,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        Text(
                                          uvIndex!,
                                          style: const TextStyle(
                                            color: Colors.white,
                                          ),
                                        ),
                                      ],
                                    )
                                  ],
                                ),
                              ],
                            ),
                          ],
                        ),
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
        : const CircularProgressIndicator();
  }
}

class HourlyForecast extends StatefulWidget {
  final String temp;
  final String hour;
  final String image;
  const HourlyForecast(
      {super.key, required this.hour, required this.temp, required this.image});

  @override
  State<HourlyForecast> createState() => _HourlyForecastState();
}

class _HourlyForecastState extends State<HourlyForecast> {
  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(
        right: 20,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Text(
            widget.hour,
            style: TextStyle(
              color: Colors.white.withAlpha(200),
            ),
          ),
          Image.network(
            widget.image,
            width: 50,
            height: 50,
          ),
          Text(
            "${widget.temp}°",
            style: const TextStyle(
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}
