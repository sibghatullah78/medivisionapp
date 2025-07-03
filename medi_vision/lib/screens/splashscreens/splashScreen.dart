import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../consts/randomCircles.dart';
import 'auth_options_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  _SplashScreenState createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    // Navigate to the next screen after 3 seconds
    Future.delayed(Duration(seconds: 4), () {
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => auth_options_screen()),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Stack(
        children: [
          // Use the RandomCirclesWidget
          RandomCirclesWidget(),  // This is the reusable widget

          // Main Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.center_focus_strong,
                  size: 100,
                  color: Colors.blueAccent.shade100,
                ),
                SizedBox(height: 20),
                Stack(
                  clipBehavior: Clip.none,
                  alignment: Alignment.center,
                  children: [
                    Text(
                      'MediVision',
                      style: GoogleFonts.abrilFatface(
                        fontSize: 50,
                        color: Colors.blueAccent.shade100,
                      ),
                    ),
                    Positioned(
                      bottom: -12, // Aligns the subtitle slightly below "MediVision"
                      left: 0, // Aligns the subtitle to the bottom-left
                      child: Text(
                        'from scribbles to digital',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.blueAccent.shade100,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
