import 'package:flutter/material.dart';
import 'package:weather_app/screens/homepage.dart';

class FavouriteLocation extends StatefulWidget {
  final String label;
  final int maxTemp;
  final int minTemp;
  final double latitude;
  final double longitude;
  final String image;
  final String assetSrc;
  const FavouriteLocation({
    super.key,
    required this.label,
    required this.maxTemp,
    required this.minTemp,
    required this.image,
    required this.latitude,
    required this.longitude,
    required this.assetSrc,
  });

  @override
  State<FavouriteLocation> createState() => _FavouriteLocationState();
}

class _FavouriteLocationState extends State<FavouriteLocation> {
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
                    locality: widget.label)),
            (route) => false);
      },
      child: ClipRRect(
        borderRadius: BorderRadius.circular(5),
        child: Stack(
          children: [
            Positioned.fill(
              child: Image.asset(
                widget.assetSrc,
                fit: BoxFit.fill,
              ),
            ),
            Container(
              decoration: BoxDecoration(
                color: Colors.black.withOpacity(0.5),
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(
                vertical: 15,
                horizontal: 20,
              ),
              decoration: BoxDecoration(
                color: Colors.grey.withOpacity(0.15),
                borderRadius: BorderRadius.circular(5),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        widget.label,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                        ),
                      ),
                      Text(
                        "${widget.maxTemp}\u00B0 / ${widget.minTemp}\u00B0",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.65),
                          fontSize: 16,
                        ),
                      )
                    ],
                  ),
                  Image.network(
                    widget.image,
                    width: 60,
                    height: 60,
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
