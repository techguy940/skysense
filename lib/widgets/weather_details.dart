import 'package:flutter/material.dart';

class Details extends StatefulWidget {
  final String asset;
  final String value;
  const Details({
    super.key,
    required this.asset,
    required this.value,
  });

  @override
  State<Details> createState() => _DetailsState();
}

class _DetailsState extends State<Details> {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Image.asset(
          widget.asset,
          width: 25,
          height: 25,
        ),
        const SizedBox(
          width: 7,
        ),
        Text(
          widget.value,
          style: const TextStyle(
            color: Colors.white,
          ),
        ),
      ],
    );
  }
}
