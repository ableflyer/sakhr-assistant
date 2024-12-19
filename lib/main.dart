import 'package:app_frontend/AuthService.dart';
import 'package:app_frontend/landing.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_core/firebase_core.dart';
import 'firebase_options.dart';
import 'navbar.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async{
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );
  await dotenv.load(fileName: ".env");
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ScreenUtilInit(
      designSize: const Size(440, 956),
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return MaterialApp(
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            fontFamily: GoogleFonts.dmMono().fontFamily,
          ),
          initialRoute: FirebaseAuth.instance.currentUser != null ? "/home" : "/",
          routes: {
            "/": (context) => const LandingScreen(),
            "/login": (context) => const LoginScreen(),
            "/signup": (context) => const SignUpScreen(),
            "/home": (context) => const NavigationManager(),
          },
        );
      },
    );
  }
}