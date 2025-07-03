import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:medi_vision_app/routes/routes.dart';
import 'package:medi_vision_app/screens/authScreens/loginScreen.dart';
import 'package:provider/provider.dart';
import 'package:medi_vision_app/screens/menu/notification_provider.dart';
import 'package:firebase_auth/firebase_auth.dart'; // Import Firebase Auth package

import 'consts/themes.dart';
import 'firebase_options.dart';

Future<void> main() async {
  runApp(const MyApp());

  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'MediVision',
        theme: AppTheme.lightTheme,
        home: const AuthWrapper(),
        onGenerateRoute: AppRoutes.generateRoute,
      ),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  // Check if the user is logged in using Firebase
  Future<User?> checkIfLoggedIn() async {
    // This checks the current user's authentication status
    final user = FirebaseAuth.instance.currentUser;
    return user; // Returns the user if logged in, else null
  }

  // Fetch the user's data (You can modify this to fetch data from Firestore)
  Future<Map<String, dynamic>?> getUserData() async {
    await Future.delayed(const Duration(milliseconds: 500));
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      // You can return user-specific data here
      return {
        'name': user.displayName ?? 'Unknown User',
        'email': user.email ?? 'Unknown Email',
      };
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<User?>(
      future: checkIfLoggedIn(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SplashScreen();
        }

        if (snapshot.data != null) {
          return FutureBuilder<Map<String, dynamic>?>(
            future: getUserData(),
            builder: (context, userSnapshot) {
              if (userSnapshot.connectionState == ConnectionState.waiting) {
                return const SplashScreen();
              }

              if (userSnapshot.hasError || userSnapshot.data == null) {
                WidgetsBinding.instance.addPostFrameCallback((_) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: const Text('Error fetching user data. Please log in again.'),
                      backgroundColor: Theme.of(context).colorScheme.error,
                    ),
                  );
                });
                return const LoginScreen();
              }

              // Navigate to the dashboard with the user data
              WidgetsBinding.instance.addPostFrameCallback((_) {
                Navigator.pushReplacementNamed(
                  context,
                  AppRoutes.dashboard,
                  arguments: userSnapshot.data!,
                );
              });

              return const SplashScreen();
            },
          );
        }

        return const LoginScreen();
      },
    );
  }
}

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'MediVision',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontFamily: 'AbrilFatface',
                color: theme.colorScheme.primary,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'from scribbles to digital',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.secondary,
              ),
            ),
            const SizedBox(height: 30),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.primary),
            ),
          ],
        ),
      ),
    );
  }
}
