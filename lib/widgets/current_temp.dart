import 'package:flutter/material.dart';

class CurrentTemperature extends StatefulWidget {
  final String temp;
  const CurrentTemperature({
    super.key,
    required this.temp,
  });

  @override
  State<CurrentTemperature> createState() => _CurrentTemperatureState();
}

class _CurrentTemperatureState extends State<CurrentTemperature> {
  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        RichText(
          text: TextSpan(
            // huge font size
            text: widget.temp,
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
    );
  }
}
