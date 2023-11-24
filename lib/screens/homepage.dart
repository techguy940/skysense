import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:google_nav_bar/google_nav_bar.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;
import 'package:weather_app/screens/favourites_scr.dart';
import 'package:weather_app/services/network.dart';
import 'package:weather_app/widgets/astro.dart';
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
import 'package:liquid_pull_to_refresh/liquid_pull_to_refresh.dart';
import 'package:awesome_notifications/awesome_notifications.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:android_alarm_manager_plus/android_alarm_manager_plus.dart';

@pragma('vm:entry-point')
Future sendNotification(double lat, double lon, int currentTemp,
    String tempCondition, String tempCondImg, String placeName) async {
  bool isAllowed = await AwesomeNotifications().isNotificationAllowed();
  if (!isAllowed) return;
  AwesomeNotifications().createNotification(
    content: NotificationContent(
      id: 10,
      channelKey: 'basic_channel',
      actionType: ActionType.Default,
      largeIcon: tempCondImg,
      title: '$currentTemp° in $placeName',
      body: "$tempCondition • See full forecast",
    ),
  );
}

@pragma('vm:entry-point')
Future<List> getCurrentTemp(double lat, double lon) async {
  String API_KEY = "";
  String base_url = "https://api.weatherapi.com/v1";
  var res = await http.get(
      Uri.parse("${base_url}/current.json?key=${API_KEY}&q=${lat},${lon}"));
  var jsonResp = jsonDecode(res.body);
  int temp = (jsonResp['current']['temp_c']).round();
  String tempCondition = jsonResp['current']['condition']['text'];
  String tempCondImg = "https:${jsonResp['current']['condition']['icon']}";
  String locality = jsonResp['location']['name'];
  return [temp, tempCondition, tempCondImg, locality];
}

@pragma('vm:entry-point')
Future checkWeatherPeriodic() async {
  final SharedPreferences prefs = await SharedPreferences.getInstance();
  String? mostRecent = prefs.getString("mostrecent");
  if (mostRecent == null) return;
  List mostRecentList = mostRecent.split(",");
  double lat = double.parse(mostRecentList[0]);
  double lon = double.parse(mostRecentList[1]);

  String? notificationSent = prefs.getString("notificationsent");
  String? notificationDate = prefs.getString("notificationdate");
  String? lastTemp = prefs.getString("lasttemp");
  String formatNow = DateFormat("yyyy-MM-dd").format(DateTime.now());
  if (notificationSent == null ||
      notificationDate != formatNow ||
      lastTemp == null ||
      notificationSent == "false") {
    List currData = await getCurrentTemp(lat, lon);
    await sendNotification(
        lat, lon, currData[0], currData[1], currData[2], currData[3]);
    prefs.setString("notificationsent", "true");
    prefs.setString("notificationdate", formatNow);
    prefs.setString("lasttemp", currData[0].toString());
    return;
  }
  int lastTempInt = int.parse(lastTemp);
  List currData = await getCurrentTemp(lat, lon);
  if ((currData[0] - lastTempInt).abs() >= 4) {
    await sendNotification(
        lat, lon, currData[0], currData[1], currData[2], currData[3]);
    prefs.setString("notificationsent", "true");
    prefs.setString("notificationdate", formatNow);
    prefs.setString("lasttemp", currData[0].toString());
    return;
  }
}

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
  // initializing all variables and constants
  String API_KEY = "";
  String AQI_API_KEY = "";
  String base_url = "https://api.weatherapi.com/v1";
  String aqi_base_url = "https://api.weatherbit.io/v2.0/current/airquality";
  String FORECAST_API_KEY = "";
  String forecast_base_url = "https://api.openweathermap.org/data/2.5/forecast";
  int _bottomNavIndex = 0;
  Position? currentPos;
  String? locality;
  String? temp;
  bool ready = false;
  bool fav = false;

  // weather data variables
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
  String? sunriseTime;
  String? sunsetTime;
  String? moonriseTime;
  String? moonsetTime;
  String? moonPhase;
  String? moonIllumation;
  bool forecastReady = false;
  List hourlyForecasts = [];
  List<Widget> dailyForecast = [];

  @override
  void initState() {
    super.initState();
    // ask for location permission and fetch weather details
    _askForPermission();
    // if notification permission is denied, ask the user to allow notifications
    AwesomeNotifications().isNotificationAllowed().then((isAllowed) {
      if (!isAllowed) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });
  }

  Future<void> _setFavouriteStatus(
      [double? latitude, double? longitude]) async {
    // get favourite places list
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favs = prefs.getString("favourites");
    List _favs = [];
    if (favs != null) {
      _favs = json.decode(favs);
    }

    // if lat, lon are passed use that else use weather or current position whichever is available
    double? lat, lon;
    if (latitude != null && longitude != null) {
      lat = latitude;
      lon = longitude;
    } else {
      if (widget.latitude != -100000 && widget.longitude != -100000) {
        lat = widget.latitude;
        lon = widget.longitude;
      } else {
        lat = currentPos?.latitude;
        lon = currentPos?.longitude;
      }
    }
    // if the current place is favourite, update the favourite status to true
    for (final place in _favs) {
      if (place['latitude'] == lat && place['longitude'] == lon) {
        setState(() {
          fav = true;
        });
        break;
      }
    }
  }

  Future<void> _getSunriseSunset() async {
    double? lat, lon;
    if (widget.latitude != -100000 && widget.longitude != -100000) {
      lat = widget.latitude;
      lon = widget.longitude;
    } else {
      lat = currentPos?.latitude;
      lon = currentPos?.longitude;
    }
    // call the api to get today's astro details
    var res = await http.get(Uri.parse(
        "https://api.weatherapi.com/v1/forecast.json?q=${lat},${lon}&days=1&key=${API_KEY}"));
    var jsonRes = jsonDecode(res.body);
    var astro = jsonRes['forecast']['forecastday'][0]['astro'];
    // set details to variables accordingly
    setState(() {
      sunriseTime = astro['sunrise'];
      sunsetTime = astro['sunset'];
      moonriseTime = astro['moonrise'];
      moonsetTime = astro['moonset'];
      moonPhase = astro['moon_phase'];
      moonIllumation = astro['moon_illumination'].toString();
    });
  }

  Future<void> _getDailyForecast(context) async {
    // set loading status
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
    bool hasNetworkConnection = await hasNetwork();
    if (!hasNetworkConnection) return;
    // if daily forecast is fetched previously, show the data
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
    // call the api to get next 5 days data
    var res = await http.get(Uri.parse(
        "${forecast_base_url}?lat=${lat}&lon=${lon}&appid=${FORECAST_API_KEY}"));
    var jsonRes = jsonDecode(res.body);
    List daily = jsonRes['list'];
    List seen = [];
    List<Widget> dailyForecastLocal = [];
    daily.forEach((data) {
      // add date to seen to avoid overwidgets
      if (seen.contains(data['dt_txt'].split(" ")[0])) {
        return;
      }
      dailyForecastLocal.add(
        DayForecast(
            day: DateFormat("EEEE")
                .format(DateTime.fromMillisecondsSinceEpoch(data['dt'] * 1000)),
            maxTemp: (data['main']['temp_max'] - 273).round(),
            minTemp: (data['main']['temp_min'] - 273).round(),
            image:
                "https://openweathermap.org/img/wn/${data['weather'][0]['icon']}.png"),
      );
      // add date to seen
      seen.add(data['dt_txt'].split(" ")[0]);
    });
    daily = daily.sublist(1, daily.length);
    setState(() {
      // set ready to true and dailyForecast to widgets
      forecastReady = true;
      dailyForecast = dailyForecastLocal;
      // remove loading and show data
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

  // fallback function if location fetching fails
  Future<bool> _wait() async {
    await Future.delayed(const Duration(seconds: 10));
    return false;
  }

  Future<void> _askForPermission() async {
    // gets shared preferences instance
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    bool hasNetworkConnection = await hasNetwork();
    // if user has no internet connection, show the most recent weather data fetched if any
    if (!hasNetworkConnection) {
      String? recentWeatherData = prefs.getString("recentweatherdata");
      if (recentWeatherData == null) {
        return;
      }
      Map data = jsonDecode(recentWeatherData);

      setState(() {
        temp = data['temp'];
        pressure = data['pressure'];
        humidity = data['humidity'];
        windSpeed = data['windSpeed'];
        locality = data['locality'];
        feelsLike = data['feelsLike'];
        tempCondition = data['tempCondition'];
        tempCondImg = data['tempCondImg'];
        uvIndex = data['uvIndex'];
        cloudPercent = data['cloudPercent'];
        precip = data['precip'];
        windGust = data['windGust'];
        hourlyForecasts = data['hourlyForecasts'];
        aqi = data['aqi'];
        sunriseTime = data['sunriseTime'];
        sunsetTime = data['sunsetTime'];
        moonriseTime = data['moonriseTime'];
        moonsetTime = data['moonsetTime'];
        moonPhase = data['moonPhase'];
        moonIllumation = data['moonIllumination'];
        bgImage = data['bgImage'];
        _setFavouriteStatus(data['latitude'], data['longitude']);
        ready = true;
        FlutterNativeSplash.remove();
        // remove splash screen as data is ready
      });
      return;
    }

    // if widget has lat, lon use that
    if (widget.longitude != -100000 && widget.latitude != -100000) {
      // set most recent to widget's lat, lon
      prefs.setString("mostrecent", "${widget.latitude},${widget.longitude}");
      // periodic function, checks every 30 mins for weather updates
      // works in background
      await AndroidAlarmManager.periodic(
          const Duration(minutes: 30), 69, checkWeatherPeriodic);

      // get current weather data, forecast data, aqi data
      var res = await http.get(Uri.parse(
          "${base_url}/current.json?key=${API_KEY}&q=${widget.latitude},${widget.longitude}"));
      var jsonResp = jsonDecode(res.body);
      var forecastRes = await http.get(Uri.parse(
          "${base_url}/forecast.json?key=${API_KEY}&q=${widget.latitude},${widget.longitude}"));
      var forecastJsonResp = jsonDecode(forecastRes.body);
      var hourlyJson = forecastJsonResp['forecast']['forecastday'][0]['hour'];
      var aqiRes = await http.get(Uri.parse(
          "${aqi_base_url}?lat=${widget.latitude}&lon=${widget.longitude}&key=${AQI_API_KEY}"));
      var aqiJson = jsonDecode(aqiRes.body);

      // parse time and set to hourlyForecastsLocal
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

      // get background image according to the weather condition code
      await _getBgImage(jsonResp['current']['condition']['code']);

      // get astro data
      await _getSunriseSunset();

      // set weather data accordingly
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
        aqi = aqiJson['data'][0]['aqi'].toString();
        Map weatherData = {
          "temp": temp,
          "pressure": pressure,
          "humidity": humidity,
          "windSpeed": windSpeed,
          "locality": locality,
          "feelsLike": feelsLike,
          "tempCondition": tempCondition,
          "tempCondImg": tempCondImg,
          "uvIndex": uvIndex,
          "cloudPercent": cloudPercent,
          "precip": precip,
          "windGust": windGust,
          "aqi": aqi,
          "hourlyForecasts": hourlyForecastsLocal,
          "bgImage": bgImage,
          "sunriseTime": sunriseTime,
          "sunsetTime": sunsetTime,
          "moonriseTime": moonriseTime,
          "moonsetTime": moonsetTime,
          "moonPhase": moonPhase,
          "moonIllumination": moonIllumation,
          "latitude": widget.latitude,
          "longitude": widget.longitude
        };
        // set the current data to recentweatherdata
        prefs.setString("recentweatherdata", jsonEncode(weatherData));
        _setFavouriteStatus();
        ready = true;
        FlutterNativeSplash.remove();
        // remove splash screen as data is ready
      });
      return;
    }

    var pos;
    try {
      // ask for location permission
      const permission = Permission.location;
      final status = await permission.request();
      pos = status.isGranted
          ? await Future.any([Geolocator.getCurrentPosition(), _wait()])
          : await Future.any([Geolocator.getCurrentPosition(), _wait()]);
      // if fetching location takes too long, fallback to default location
      if (pos == false) {
        throw Exception();
      }
    } catch (e) {
      pos = Position(
        latitude: 25.4358,
        longitude: 81.8463,
        timestamp: DateTime.now(),
        accuracy: 0,
        altitude: 0,
        altitudeAccuracy: 0,
        heading: 0,
        headingAccuracy: 0,
        speed: 0,
        speedAccuracy: 0,
      );
    }

    // set most recent position data to live location lat, lon
    prefs.setString("mostrecent", "${pos?.latitude},${pos?.longitude}");

    // periodic function, checks every 30 mins for weather updates
    // works in background
    await AndroidAlarmManager.periodic(
        const Duration(minutes: 30), 69, checkWeatherPeriodic);

    // fetch current weather data, forecast data, aqi data
    var res = await http.get(Uri.parse(
        "${base_url}/current.json?key=${API_KEY}&q=${pos?.latitude},${pos?.longitude}"));
    var jsonResp = jsonDecode(res.body);
    var forecastRes = await http.get(Uri.parse(
        "${base_url}/forecast.json?key=${API_KEY}&q=${pos?.latitude},${pos?.longitude}"));
    var forecastJsonResp = jsonDecode(forecastRes.body);
    var hourlyJson = forecastJsonResp['forecast']['forecastday'][0]['hour'];
    var aqiRes = await http.get(Uri.parse(
        "${aqi_base_url}?lat=${pos?.latitude}&lon=${pos?.longitude}&key=${AQI_API_KEY}"));
    var aqiJson = jsonDecode(aqiRes.body);

    // parse hour and set it to hourlyForecastsLocal
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

    // get background image according to weather condition code
    await _getBgImage(jsonResp['current']['condition']['code']);

    // get astro data
    await _getSunriseSunset();

    // set variables accordingly
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
      aqi = aqiJson['data'][0]['aqi'].toString();
      hourlyForecasts = hourlyForecastsLocal;
      Map weatherData = {
        "temp": temp,
        "pressure": pressure,
        "humidity": humidity,
        "windSpeed": windSpeed,
        "locality": locality,
        "feelsLike": feelsLike,
        "tempCondition": tempCondition,
        "tempCondImg": tempCondImg,
        "uvIndex": uvIndex,
        "cloudPercent": cloudPercent,
        "precip": precip,
        "windGust": windGust,
        "aqi": aqi,
        "hourlyForecasts": hourlyForecastsLocal,
        "bgImage": bgImage,
        "sunriseTime": sunriseTime,
        "sunsetTime": sunsetTime,
        "moonriseTime": moonriseTime,
        "moonsetTime": moonsetTime,
        "moonPhase": moonPhase,
        "moonIllumination": moonIllumation,
        "latitude": pos?.latitude,
        "longitude": pos?.longitude
      };
      // set current weather data to most recently fetched data
      prefs.setString("recentweatherdata", jsonEncode(weatherData));
      // set favourite status by latitude, longitude
      _setFavouriteStatus();
      ready = true;
      FlutterNativeSplash.remove();
      // remove splash screen as data is ready
    });
  }

  Future<int> _getBgImage(int code) async {
    // gets background image as per the weather condition code
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

    // parse hour to 24 hour format
    int hour = int.parse(DateFormat("HH").format(DateTime.now()));
    if (code == 1000) {
      if (hour > 5 && hour < 18) {
        imagePath += "day-dark.jpg";
      } else {
        imagePath += "night-dark.jpg";
      }
    } else {
      imagePath += codes_map[code].split(".")[0] + "-dark.jpg";
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
            bottomNavigationBar: Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 15,
              ),
              decoration: BoxDecoration(color: Colors.black.withOpacity(0.8)),
              child: GNav(
                // nav bar
                selectedIndex: _bottomNavIndex,
                onTabChange: (value) {
                  setState(() {
                    _bottomNavIndex = value;
                    if (_bottomNavIndex == 1) {
                      // push search screen
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
                      // push favourites screen
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
                  });
                },
                rippleColor: Colors
                    .grey.shade800, // tab button ripple color when pressed
                hoverColor: Colors.grey.shade700, // tab button hover color
                tabBorderRadius: 15,
                duration: Duration(milliseconds: 100), // tab animation duration
                gap: 8, // the tab button gap between icon and text
                color: Colors.grey[800], // unselected icon color
                activeColor: Colors.white, // selected icon and text color
                iconSize: 24, // tab button icon size
                tabBackgroundColor: Colors.white
                    .withOpacity(0.1), // selected tab background color
                padding: EdgeInsets.symmetric(
                    horizontal: 20, vertical: 10), // navigation bar padding
                tabs: [
                  GButton(
                    icon: Icons.home_rounded,
                    text: 'Home',
                  ),
                  GButton(
                    icon: Icons.search_rounded,
                    text: 'Search',
                  ),
                  GButton(
                    icon: Icons.favorite,
                    text: 'Favourites',
                  ),
                ],
              ),
            ),
            body: SafeArea(
              child: LiquidPullToRefresh(
                onRefresh: () async {
                  // fetches current weather data
                  await _askForPermission();
                },
                child: Column(
                  children: [
                    Expanded(
                      child: ListView(
                        children: [
                          Stack(
                            children: [
                              Image.asset(
                                // background weather image
                                bgImage!,
                                fit: BoxFit.fill,
                                height:
                                    MediaQuery.of(context).size.height * 1.18,
                                // height: double.infinity,
                              ),
                              Column(
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 30,
                                      vertical: 20,
                                    ),
                                    child: Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      crossAxisAlignment:
                                          CrossAxisAlignment.center,
                                      children: [
                                        PlaceName(label: locality!),
                                        IconButton(
                                          onPressed: () async {
                                            // get shared preferences instance
                                            final SharedPreferences prefs =
                                                await SharedPreferences
                                                    .getInstance();
                                            String? favs =
                                                prefs.getString("favourites");
                                            // get favourites list
                                            List _favs = [];
                                            if (favs != null) {
                                              _favs = json.decode(favs);
                                            }
                                            var label =
                                                widget.latitude == -100000
                                                    ? locality
                                                    : widget.locality;
                                            var latitude =
                                                widget.latitude == -100000
                                                    ? currentPos!.latitude
                                                    : widget.latitude;
                                            var longitude =
                                                widget.latitude == -100000
                                                    ? currentPos!.longitude
                                                    : widget.longitude;
                                            // add to favourite places
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
                                              // remove from favourite places
                                              for (final elem in _favs) {
                                                if (elem['label'] == label &&
                                                    elem['latitude'] ==
                                                        latitude &&
                                                    elem['longitude'] ==
                                                        longitude) {
                                                  _favs.remove(elem);
                                                  break;
                                                }
                                              }
                                              prefs.setString(
                                                "favourites",
                                                json.encode(_favs),
                                              );
                                            }
                                            // set fav to true if false and vice-versa to update icon
                                            setState(() {
                                              fav = !fav;
                                            });
                                          },
                                          icon: Icon(
                                            fav
                                                ? Icons.favorite
                                                : Icons.favorite_border_rounded,
                                            color:
                                                fav ? Colors.red : Colors.white,
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
                                    crossAxisAlignment:
                                        CrossAxisAlignment.center,
                                    children: [
                                      CurrentTemperature(
                                          temp:
                                              temp!), // current temperature widge
                                      Text(
                                        // feels like temperature
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
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceEvenly,
                                      children: [
                                        // some major metrics
                                        Details(
                                          asset:
                                              "assets/air-pressure-white.png",
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
                                  // metrics data
                                  Metrics(
                                    tempCondition: tempCondition!,
                                    uvIndex: uvIndex!,
                                    precip: precip!,
                                    cloudPercent: cloudPercent!,
                                    windGust: windGust!,
                                    aqi: aqi!,
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
                                          mainAxisAlignment:
                                              MainAxisAlignment.spaceBetween,
                                          children: [
                                            const Text(
                                              "Today",
                                              style: TextStyle(
                                                fontWeight: FontWeight.bold,
                                                color: Colors.white,
                                              ),
                                            ),
                                            InkWell(
                                              onTap: () =>
                                                  _getDailyForecast(context),
                                              // next 5 days forecast
                                              child: const Text(
                                                "Next 5 Days",
                                                style: TextStyle(
                                                  color: Colors.white,
                                                  decoration:
                                                      TextDecoration.underline,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                        const SizedBox(
                                          height: 10,
                                        ),
                                        Container(
                                          // hourly forecast
                                          width: double.infinity,
                                          padding: const EdgeInsets.all(10),
                                          height: 115,
                                          decoration: BoxDecoration(
                                            color: Colors.grey.shade400
                                                .withOpacity(0.2),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                          child: ListView(
                                            physics:
                                                const BouncingScrollPhysics(),
                                            scrollDirection: Axis.horizontal,
                                            children:
                                                hourlyForecasts.map((data) {
                                              return HourlyForecast(
                                                hour: data['hour'],
                                                temp: data['temp'],
                                                image: data['image'],
                                              );
                                            }).toList(),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                  // astrology data widget
                                  Astro(
                                    sunriseTime: sunriseTime!,
                                    sunsetTime: sunsetTime!,
                                    moonriseTime: moonriseTime!,
                                    moonsetTime: moonsetTime!,
                                    moonPhase: moonPhase!,
                                    moonIllumation: moonIllumation!,
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          )
        : const Column(
            // show loading while data is loading
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircularProgressIndicator(),
            ],
          );
  }
}
