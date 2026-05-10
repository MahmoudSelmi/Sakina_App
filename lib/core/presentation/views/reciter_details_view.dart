import 'package:flutter/material.dart';

class ReciterDetailsView extends StatelessWidget {
  final String name;
  final String image;

  const ReciterDetailsView({
    super.key,
    required this.name,
    required this.image,
  });

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Text(
          name,
          style: const TextStyle(color: Colors.white, fontSize: 30),
        ),
      ),
    );
  }
}
