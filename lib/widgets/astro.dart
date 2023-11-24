import 'package:flutter/material.dart';
import 'package:weather_app/widgets/metric.dart';

class Astro extends StatefulWidget {
  final String sunriseTime;
  final String sunsetTime;
  final String moonriseTime;
  final String moonsetTime;
  final String moonPhase;
  final String moonIllumation;
  const Astro({
    super.key,
    required this.sunriseTime,
    required this.sunsetTime,
    required this.moonriseTime,
    required this.moonsetTime,
    required this.moonPhase,
    required this.moonIllumation,
  });

  @override
  State<Astro> createState() => _AstroState();
}

class _AstroState extends State<Astro> {
  @override
  Widget build(BuildContext context) {
    return Container(
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
            "Astro",
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Metric(
                    label: "SUNRISE",
                    value: widget.sunriseTime,
                  ),
                  Metric(
                    label: "SUNSET     ",
                    value: widget.sunsetTime,
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Metric(
                    label: "MOONRISE",
                    value: widget.moonriseTime,
                  ),
                  Metric(
                    label: "MOONSET  ",
                    value: widget.moonsetTime,
                  ),
                ],
              ),
              const SizedBox(
                height: 10,
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Metric(
                    label: "MOON PHASE",
                    value: widget.moonPhase,
                  ),
                  Metric(
                    label: "ILLUMINATE",
                    value: "${widget.moonIllumation}%",
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}
