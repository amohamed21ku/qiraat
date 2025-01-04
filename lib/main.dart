import 'package:arabic_font/arabic_font.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:qiraat/Screens/LoginScreen.dart';
import 'package:qiraat/Screens/SignupScreen.dart';

import 'Screens/HomeScreen.dart';
import 'Screens/WelcomeScreen.dart';
import 'firebase_options.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      theme: ThemeData(
        fontFamily:
            ArabicThemeData.font(arabicFont: ArabicFont.dinNextLTArabic),
        package: ArabicThemeData.package,
      ),
      initialRoute: 'welcomescreen',
      routes: {
        "welcomescreen": (context) => const WelcomeScreen(),
        "loginscreen": (context) => const LoginScreen(),
        'homescreen': (context) => const HomeScreen(),
        'signup': (context) => const SignUpScreen(),
      },
    );
  }
}
