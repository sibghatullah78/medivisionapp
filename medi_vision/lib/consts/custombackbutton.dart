import 'package:flutter/material.dart';

class CustomBackButton extends StatelessWidget {
  final Color iconColor;
  final Color backgroundColor;
  final double iconSize;
  final VoidCallback? onPressed;
  final dynamic dataToPassBack; // Data to pass back

  const CustomBackButton({
    super.key,
    this.iconColor = Colors.black,
    this.backgroundColor = Colors.white,
    this.iconSize = 24.0,
    this.onPressed,
    this.dataToPassBack, // New field for passing data back
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(12),
      ),
      child: IconButton(
        icon: Icon(Icons.arrow_back, color: iconColor, size: iconSize),
        onPressed: () {
          if (onPressed != null) {
            onPressed!();
          } else {
            Navigator.pop(context, dataToPassBack); // Pass data when popping screen
          }
        },
      ),
    );
  }
}
