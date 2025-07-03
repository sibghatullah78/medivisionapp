import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class auth_options_screen extends StatelessWidget {
  const auth_options_screen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Center(
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
            SizedBox(height: 200),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/login'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.shade100,
                padding: EdgeInsets.symmetric(horizontal: 130, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Login',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () => Navigator.pushNamed(context, '/register'),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blueAccent.shade100,
                padding: EdgeInsets.symmetric(horizontal: 115, vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: Text(
                'Register',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
