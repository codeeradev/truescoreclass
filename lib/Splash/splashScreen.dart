import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:online_classes/Screens/Auth/signinScreen.dart';
import 'package:online_classes/Screens/Teachers/screens/TeacherDashboardScreen.dart';
import 'package:online_classes/widgets/BottomNavigationBar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:upgrader/upgrader.dart';

import '../Screens/IntroScreen.dart';
import '../Screens/Student/Bottombar.dart';
import '../Screens/Student/DasgBoradScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  Future<void> checkForUpdate() async {
    final upgrader = Upgrader();

    await upgrader.initialize();

    if (upgrader.isUpdateAvailable()) {
      return;
    }

    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return; // widget might be disposed

      final prefs = await SharedPreferences.getInstance();
      final check = prefs.getString('type') ?? ''; // safe fallback
      if (check == 'teacher') {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => TeacherDashboardScreen(),
            ),
            (route) => false);
        return;
      } else if (check == 'student') {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => ModernBottomNav(),
            ),
            (route) => false);

        return;
      } else {
        Navigator.pushAndRemoveUntil(
            context,
            MaterialPageRoute(
              builder: (context) => OnBoardingPage(),
            ),
            (route) => false);

        return;
      }
    });
  }

  @override
  void initState() {
    super.initState();
    checkForUpdate();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Container(
                height: MediaQuery.of(context).size.height * 0.3,
                child: Image.asset(
                  'assets/images/logo.png',
                  fit: BoxFit.cover,
                ),
              ),
              Container(
                child: Lottie.asset(
                  'assets/images/splash.json',
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height * 0.6,
                  fit: BoxFit.contain,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
