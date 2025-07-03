import 'dart:io';
import 'package:flutter/material.dart';

import '../screens/ProfileScreen/profile_screen.dart';
import '../screens/authScreens/forgetpassword.dart';
import '../screens/authScreens/loginScreen.dart';
import '../screens/authScreens/registerScreen.dart';
import '../screens/documents/MedicineScreen/medicine_scan_page.dart';
import '../screens/documents/ScanDocScreen.dart';
import '../screens/mainScreens/DashboardScreen/dashbaord.dart';
import '../screens/splashscreens/auth_options_screen.dart';
import '../screens/splashscreens/splashScreen.dart' show SplashScreen;

class AppRoutes {
  static const String register = '/register';
  static const String login = '/login';
  static const String authOption = '/authOption';
  static const String dashboard = '/dashboard';
  static const String splash = '/splash';
  static const String myDoc = '/mydocmain';
  static const String scanDocScreen = '/scandocscreen';
  static const String medicineDetail = '/medidetail';
  static const String forgetPass = '/forgetpassword';
  static const String profile = '/profile';

  static Route<dynamic> generateRoute(RouteSettings settings) {
    print('Generating route: ${settings.name} with arguments: ${settings.arguments}'); // Debug
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(builder: (_) => SplashScreen());

      case register:
        return MaterialPageRoute(builder: (_) => RegisterScreen());

      case scanDocScreen:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => ScanDocumentScreen(userData: args),
        );

      case forgetPass:
        return MaterialPageRoute(builder: (_) => const ForgetPassScreen());

      case medicineDetail:
        final args = settings.arguments as Map<String, dynamic>? ?? {};
        if (args['imageFile'] == null) {
          return MaterialPageRoute(
            builder: (_) => const Scaffold(
              body: Center(child: Text('Image file is required')),
            ),
          );
        }
        return MaterialPageRoute(
          builder: (_) => MedicineScanPage(
            scanData: args['scanData'] ?? {},
            imageFile: args['imageFile']! as File,
          ),
        );




      case login:
        return MaterialPageRoute(builder: (_) => LoginScreen());

      case authOption:
        return MaterialPageRoute(builder: (_) => auth_options_screen());

      case dashboard:
        final args = settings.arguments as Map<String, dynamic>?;
        return MaterialPageRoute(
          builder: (_) => Dashboard(
            userData: args != null && args.containsKey('userData') ? args['userData'] : null,
            scannedImage: args != null && args.containsKey('scannedImage') ? args['scannedImage'] as File? : null,
          ),
        );

      case profile:
      // No arguments needed since ProfileScreen fetches data from Firestore
        return MaterialPageRoute(
          builder: (_) => const ProfileScreen(),
        );

      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('No route defined for ${settings.name}'),
            ),
          ),
        );
    }
  }
}