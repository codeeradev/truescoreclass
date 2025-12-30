import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:online_classes/Screens/Auth/signinScreen.dart';
import 'package:online_classes/Screens/Teachers/screens/TeacherDashboardScreen.dart';
import 'package:online_classes/widgets/BottomNavigationBar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Screens/IntroScreen.dart';
import '../Screens/Student/Bottombar.dart';
import '../Screens/Student/DasgBoradScreen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    Future.delayed(const Duration(seconds: 3), () async {
      if (!mounted) return; // widget might be disposed

      final prefs = await SharedPreferences.getInstance();
      final check = prefs.getString('type') ?? ''; // safe fallback
      print("type: $check");

      if (check == 'teacher') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const TeacherDashboardScreen()),
        );
        return;
      } else if (check == 'student') {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const ModernBottomNav()),
        );
        return;
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (_) => const OnBoardingPage()),
        );
        return;
      }
    });

  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Center(
          child: Column(
            children: [
              Container(height: MediaQuery.of(context).size.height*0.3
                ,child: Image.asset('assets/images/logo.png',fit: BoxFit.cover,),),

              Container(

                child:  Lottie.asset(
                  'assets/images/splash.json',
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height*0.6,
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

