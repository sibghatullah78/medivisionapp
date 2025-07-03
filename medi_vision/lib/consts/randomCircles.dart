import 'package:flutter/material.dart';

class RandomCirclesWidget extends StatelessWidget {
  const RandomCirclesWidget({super.key});

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        // Bottom-left large circle
        Positioned(
          bottom: -50,
          left: -50,
          child: CircleAvatar(
            radius: 100,
            backgroundColor: Colors.blueAccent.shade100.withOpacity(0.3),
          ),
        ),

        // Top-left small circle
        Positioned(
          top: 50,
          left: 50,
          child: CircleAvatar(
            radius: 25,
            backgroundColor: Colors.blueAccent.shade100.withOpacity(0.4),
          ),
        ),

        // Center-right small circle
        Positioned(
          top: MediaQuery.of(context).size.height / 2 - 50,
          right: 30,
          child: CircleAvatar(
            radius: 20,
            backgroundColor: Colors.blueAccent.shade100.withOpacity(0.4),
          ),
        ),

        // Top-center medium circle
        Positioned(
          top: 30,
          left: MediaQuery.of(context).size.width / 2 - 40,
          child: CircleAvatar(
            radius: 30,
            backgroundColor: Colors.blueAccent.shade100.withOpacity(0.3),
          ),
        ),
      ],
    );
  }
}
