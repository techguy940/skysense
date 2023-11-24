import 'package:flutter/material.dart';

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
            // weather condition image
            widget.image,
            width: 50,
            height: 50,
            // if fetching failed, show error icon
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              return const SizedBox(
                width: 50,
                height: 50,
                child: Icon(
                  Icons.error_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              );
            },
          ),
          Text(
            // hourly temp
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
