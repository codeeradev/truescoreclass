import 'package:flutter/material.dart';
import 'package:online_classes/Screens/AddQuestionsScreen.dart';
import 'package:online_classes/Screens/HomeScreen.dart';
import 'package:online_classes/Screens/Teachers/screens/TeacherDashboardScreen.dart';
import 'package:online_classes/servcies.dart';
import 'package:online_classes/widgets/BottomNavigationBar.dart';
import 'package:provider/provider.dart';
import 'package:online_classes/Splash/splashScreen.dart';
import 'Screens/All Courses.dart';
import 'Screens/Auth/signinScreen.dart';
import 'Screens/Batchscreen.dart';
import 'Screens/MCQQuestion.dart';
import 'Screens/SearchProvider.dart';
import 'Screens/Student/Bottombar.dart';
import 'Screens/Student/DasgBoradScreen.dart';

void main() {
  runApp(
    ChangeNotifierProvider(
      create: (_) => SearchProvider(),
      child: const MyApp(),
    ),
  );
  SecureScreen.enable();

}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: SplashScreen(),
    );
  }
}
