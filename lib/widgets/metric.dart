import 'package:flutter/material.dart';

class Metric extends StatefulWidget {
  final String label;
  final String value;
  const Metric({
    super.key,
    required this.label,
    required this.value,
  });

  @override
  State<Metric> createState() => _MetricState();
}

class _MetricState extends State<Metric> {
  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          // metric label
          widget.label,
          style: const TextStyle(
            color: Color.fromRGBO(200, 200, 200, 1),
            letterSpacing: 2,
            fontWeight: FontWeight.bold,
          ),
        ),
        Text(
          // metric value
          widget.value,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
