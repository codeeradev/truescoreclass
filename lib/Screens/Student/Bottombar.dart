import 'package:flutter/material.dart';
import 'package:online_classes/Screens/Student/profilescreen.dart';
import '../All Courses.dart';
import '../ProfileScreen.dart';
import '../SearchScreen.dart';
import 'ADDdoubtsbystudents.dart';
import 'DasgBoradScreen.dart';
import 'Mydoubtsscreen.dart';

class ModernBottomNav extends StatefulWidget {
  const ModernBottomNav({super.key});

  @override
  State<ModernBottomNav> createState() => _ModernBottomNavState();
}

class _ModernBottomNavState extends State<ModernBottomNav> {
  int selectedIndex = 0;

  final pages = [
    StudentDashboardScreen(),
    //CoursesScreen(),
    CourseSearchScreen(),
    GetDoubtsScreenstudent(),
    ProfileScreen1(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: pages[selectedIndex],

        /// ✅ NORMAL BOTTOM BAR (OLD STYLE)
        bottomNavigationBar: BottomNavigationBar(
          currentIndex: selectedIndex,
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: Colors.blue,
          unselectedItemColor: Colors.grey,
          selectedFontSize: 12,
          unselectedFontSize: 12,
          elevation: 10,

          onTap: (index) {
            setState(() => selectedIndex = index);
          },

          items: const [
            BottomNavigationBarItem(
              icon: Icon(Icons.home_rounded),
              label: "Home",
            ),
            // BottomNavigationBarItem(
            //   icon: Icon(Icons.book_outlined),
            //   label: "Courses",
            // ),
            BottomNavigationBarItem(
              icon: Icon(Icons.search_rounded),
              label: "Search",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.help),
              label: "Doubts",
            ),
            BottomNavigationBarItem(
              icon: Icon(Icons.person_rounded),
              label: "Profile",
            ),
          ],
        ),
      ),
    );
  }

  /// 🔙 Back button handling
  Future<bool> _onWillPop() async {
    if (selectedIndex != 0) {
      setState(() => selectedIndex = 0);
      return false;
    }

    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exit App"),
        content: const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text("Exit"),
          ),
        ],
      ),
    ) ??
        false;
  }
}
