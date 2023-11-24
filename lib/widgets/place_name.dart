import 'package:flutter/material.dart';

class PlaceName extends StatefulWidget {
  final String label;
  const PlaceName({
    super.key,
    required this.label,
  });

  @override
  State<PlaceName> createState() => _PlaceNameState();
}

class _PlaceNameState extends State<PlaceName> {
  @override
  Widget build(BuildContext context) {
    return Row(
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
          // shows place name
          widget.label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 26,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }
}
