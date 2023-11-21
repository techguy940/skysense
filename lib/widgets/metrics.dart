import 'package:flutter/material.dart';
import 'package:weather_app/widgets/metric.dart';

class Metrics extends StatefulWidget {
  final String tempCondition;
  final String uvIndex;
  final String precip;
  final String cloudPercent;
  final String windGust;
  final String aqi;
  const Metrics({
    super.key,
    required this.tempCondition,
    required this.uvIndex,
    required this.precip,
    required this.cloudPercent,
    required this.windGust,
    required this.aqi,
  });

  @override
  State<Metrics> createState() => _MetricsState();
}

class _MetricsState extends State<Metrics> {
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
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Metric(
                    label: "CONDITION",
                    value: widget.tempCondition,
                  ),
                  Metric(
                    label: "ULTRAVIOLET",
                    value: widget.uvIndex,
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
                    label: "PRECIPITATION",
                    value: "${widget.precip} mm",
                  ),
                  Metric(
                    label: "CLOUDINESS",
                    value: "${widget.cloudPercent}%",
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
                    label: "WIND GUST",
                    value: "${widget.windGust} kmph",
                  ),
                  // Todo: Fetch AQI
                  Metric(
                    label: "AIR QUALITY",
                    value: widget.aqi,
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
