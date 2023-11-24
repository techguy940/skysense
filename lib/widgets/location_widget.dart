import 'package:flutter/material.dart';
import 'package:weather_app/screens/homepage.dart';

class Location extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String label;
  const Location({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.label,
  });

  @override
  State<Location> createState() => _LocationState();
}

class _LocationState extends State<Location> {
  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => HomePage(
                latitude: widget.latitude,
                longitude: widget.longitude,
                locality: widget.label.split(",")[0],
              ),
            ),
            (route) => false);
      },
      child: Container(
        padding: const EdgeInsets.all(20),
        margin: const EdgeInsets.symmetric(vertical: 2),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(5),
          color: const Color.fromRGBO(36, 96, 155, 0.13),
        ),
        child: Row(
          children: [
            Icon(
              Icons.location_on_outlined,
              color: Colors.black.withAlpha(150),
            ),
            const SizedBox(
              width: 20,
            ),
            Text(
              // shows place name
              widget.label,
              style: const TextStyle(
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
