import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:weather_app/widgets/favourite_widget.dart';

String getBgImage(int code) {
  // gets the background image by weather condition code
  Map codesMap = {
    1000: 'CheckForDayNight-dark.jpg',
    1003: 'drizzle-dark.jpg',
    1006: 'clouds-dark.jpg',
    1009: 'clouds-dark.jpg',
    1030: 'mist-dark.jpg',
    1063: 'drizzle-dark.jpg',
    1066: 'snow-dark.jpg',
    1069: 'drizzle-dark.jpg',
    1072: 'drizzle-dark.jpg',
    1087: 'thunderstorm-dark.jpg',
    1114: 'snow-dark.jpg',
    1117: 'snow-dark.jpg',
    1135: 'mist-dark.jpg',
    1147: 'mist-dark.jpg',
    1150: 'drizzle-dark.jpg',
    1153: 'drizzle-dark.jpg',
    1168: 'drizzle-dark.jpg',
    1171: 'drizzle-dark.jpg',
    1180: 'drizzle-dark.jpg',
    1183: 'drizzle-dark.jpg',
    1186: 'rain-dark.jpg',
    1189: 'rain-dark.jpg',
    1192: 'rain-dark.jpg',
    1195: 'rain-dark.jpg',
    1198: 'rain-dark.jpg',
    1201: 'snow-dark.jpg',
    1204: 'snow-dark.jpg',
    1207: 'snow-dark.jpg',
    1210: 'snow-dark.jpg',
    1213: 'snow-dark.jpg',
    1216: 'snow-dark.jpg',
    1219: 'snow-dark.jpg',
    1222: 'snow-dark.jpg',
    1225: 'snow-dark.jpg',
    1237: 'snow-dark.jpg',
    1240: 'rain-dark.jpg',
    1243: 'rain-dark.jpg',
    1246: 'rain-dark.jpg',
    1249: 'snow-dark.jpg',
    1252: 'snow-dark.jpg',
    1255: 'snow-dark.jpg',
    1258: 'snow-dark.jpg',
    1261: 'snow-dark.jpg',
    1264: 'snow-dark.jpg',
    1273: 'snow-dark.jpg',
    1276: 'snow-dark.jpg',
    1279: 'snow-dark.jpg',
    1282: 'snow-dark.jpg'
  };
  String imagePath = "assets/";
  // format hour to be 24 hour format
  int hour = int.parse(DateFormat("HH").format(DateTime.now()));
  if (code == 1000) {
    if (hour > 5 && hour < 18) {
      imagePath += "day-dark.jpg";
    } else {
      imagePath += "night-dark.jpg";
    }
  } else {
    imagePath += codesMap[code];
  }
  return imagePath;
}

class Favourites extends StatefulWidget {
  const Favourites({super.key});

  @override
  State<Favourites> createState() => _FavouritesState();
}

class _FavouritesState extends State<Favourites> {
  // initialize all variables and constants
  // ready corresponds to if data is ready to show
  bool ready = false;
  // favourite places list
  List favourites = [];
  // api key and base url for fetching data
  String API_KEY = "";
  String base_url = "https://api.weatherapi.com/v1";

  @override
  void initState() {
    super.initState();
    _getFavourites();
  }

  Future<void> _getFavourites() async {
    // get stored favourite places
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    String? favs = prefs.getString("favourites");
    List _favs = [];
    if (favs != null) {
      _favs = json.decode(favs);
    }
    List favouritesLocal = [];

    // for each place, fetch its current weather data
    for (final elem in _favs) {
      var res = await http.get(Uri.parse(
          "${base_url}/forecast.json?key=${API_KEY}&q=${elem['latitude']},${elem['longitude']}&days=1"));
      var jsonResp = jsonDecode(res.body);
      var data = jsonResp['forecast']['forecastday'][0];
      int maxTemp = data['day']['maxtemp_c'].round();
      int minTemp = data['day']['mintemp_c'].round();
      String image = "https:${data['day']['condition']['icon']}";
      int code = data['day']['condition']['code'];
      String assetSrc = getBgImage(code);

      // add favourite location variable
      favouritesLocal.add(FavouriteLocation(
        label: elem['label'],
        latitude: elem['latitude'],
        longitude: elem['longitude'],
        maxTemp: maxTemp,
        minTemp: minTemp,
        image: image,
        assetSrc: assetSrc,
      ));
      // to add spacing between two places
      favouritesLocal.add(
        const SizedBox(
          height: 10,
        ),
      );
    }

    // set variables accordinly
    setState(() {
      favourites = favouritesLocal;
      ready = true;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ready == true
            ? SingleChildScrollView(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        "Favourites",
                        style: TextStyle(
                          color: Color.fromRGBO(36, 96, 155, 1),
                          fontSize: 26,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(
                        height: 20,
                      ),
                      ...favourites,
                    ],
                  ),
                ),
              )
            : const SizedBox(
                // loading while data is being fetched
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
    );
  }
}
