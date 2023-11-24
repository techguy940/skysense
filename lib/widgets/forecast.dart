import 'package:flutter/material.dart';

class DayForecast extends StatefulWidget {
  final String day;
  final int maxTemp;
  final int minTemp;
  final String image;
  const DayForecast({
    super.key,
    required this.day,
    required this.maxTemp,
    required this.minTemp,
    required this.image,
  });

  @override
  State<DayForecast> createState() => _DayForecastState();
}

class _DayForecastState extends State<DayForecast> {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        vertical: 15,
        horizontal: 20,
      ),
      decoration: BoxDecoration(
        color: Colors.grey.withOpacity(0.13),
        borderRadius: BorderRadius.circular(5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                widget.day,
                style: const TextStyle(
                  color: Color.fromRGBO(36, 96, 155, 1),
                  fontSize: 18,
                ),
              ),
              Text(
                // max and min temperature
                "${widget.maxTemp}\u00B0 / ${widget.minTemp}\u00B0",
                style: const TextStyle(
                  color: Color.fromARGB(175, 127, 127, 127),
                ),
              )
            ],
          ),
          Image.network(
            // weather condition code
            widget.image,
            width: 60,
            height: 60,
            // if fetching failed, return error icon
            errorBuilder: (BuildContext context, Object exception,
                StackTrace? stackTrace) {
              return const SizedBox(
                width: 60,
                height: 60,
                child: Icon(
                  Icons.error_outlined,
                  color: Colors.white,
                  size: 30,
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
