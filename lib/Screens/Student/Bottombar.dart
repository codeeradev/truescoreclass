import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:online_classes/Screens/Student/profilescreen.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../servcies.dart';
import '../All Courses.dart';
import '../ProfileScreen.dart';
import '../SearchScreen.dart';
import 'DasgBoradScreen.dart';
import 'Mydoubtsscreen.dart';
import 'purchasedcourses.dart';

class ModernBottomNav extends StatefulWidget {
  const ModernBottomNav({super.key});

  @override
  State<ModernBottomNav> createState() => _ModernBottomNavState();
}

class _ModernBottomNavState extends State<ModernBottomNav> {
  int selectedIndex = 0;

  List<dynamic> doubts = [];
  int unreadCount = 0;

  final List<Widget> pages = [
    StudentDashboardScreen(),
    MyOnlyPurchased(),
    CourseSearchScreen(),
    GetDoubtsScreenstudent(),
    ProfileScreen1(),
  ];

  bool get showFab => selectedIndex == 0 || selectedIndex == 1;
  bool get showBottomBar => selectedIndex != 2;

  @override
  void initState() {
    super.initState();
    SecureScreen.enable();
    fetchDoubts();
  }

  //---------------- FETCH DOUBTS ----------------//
  Future<void> fetchDoubts() async {
    final prefs = await SharedPreferences.getInstance();
    final token = prefs.getString('token');

    if (token == null) return;

    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/get-doubts"),
        body: {"apiToken": token},
      );

      if (response.statusCode == 200) {
        final json = jsonDecode(response.body);

        if (json['status'] == 1) {
          final data = json['data'] ?? [];

          /// 🔥 GET SAVED SEEN COUNT
          int seenCount = prefs.getInt("seen_doubts_count") ?? 0;

          /// 🔥 CALCULATE UNREAD
          int newUnread = data.length - seenCount;
          if (newUnread < 0) newUnread = 0;

          setState(() {
            doubts = data;
            unreadCount = newUnread;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching doubts: $e");
    }
  }

  //---------------- UI ----------------//
  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen =
        MediaQuery.of(context).viewInsets.bottom > 0;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,

        body: IndexedStack(
          index: selectedIndex,
          children: pages,
        ),

        /// FAB
        floatingActionButton: isKeyboardOpen
            ? null
            : FloatingActionButton(
          backgroundColor: Colors.black,
          elevation: 8,
          onPressed: () {
            setState(() => selectedIndex = 2);
          },
          child: const Icon(Icons.search,
              color: Colors.white, size: 28),
        ),

        floatingActionButtonLocation:
        FloatingActionButtonLocation.centerDocked,

        /// BOTTOM BAR
        bottomNavigationBar: isKeyboardOpen || !showBottomBar
            ? const SizedBox.shrink()
            : BottomAppBar(
          color: Colors.white,
          elevation: 12,
          shape: const CircularNotchedRectangle(),
          notchMargin: 8,
          child: SizedBox(
            height: 65,
            child: Row(
              mainAxisAlignment:
              MainAxisAlignment.spaceAround,
              children: [
                _navItem(Icons.home_rounded, "Home", 0),
                _navItem(Icons.monetization_on,
                    "Purchased", 1),
                const SizedBox(width: 40),
                _navItem(Icons.help, "Doubts", 3),
                _navItem(
                    Icons.person_rounded, "Profile", 4),
              ],
            ),
          ),
        ),
      ),
    );
  }

  //---------------- NAV ITEM ----------------//
  Widget _navItem(IconData icon, String label, int index) {
    final bool isSelected = selectedIndex == index;
    final bool showBadge = index == 3 && unreadCount > 0;

    return InkWell(
      onTap: () async {
        /// 🔥 RESET COUNT WHEN OPEN DOUBTS
        if (index == 3) {
          final prefs = await SharedPreferences.getInstance();
          await prefs.setInt("seen_doubts_count", doubts.length);

          setState(() {
            unreadCount = 0;
          });
        }

        setState(() => selectedIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                color: isSelected ? Colors.blue : Colors.grey,
                size: 24,
              ),

              /// 🔴 NUMBER BADGE
              if (showBadge)
                Positioned(
                  top: -6,
                  right: -10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99
                          ? "99+"
                          : unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isSelected ? Colors.blue : Colors.grey,
              fontWeight:
              isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  //---------------- BACK BUTTON ----------------//
  Future<bool> _onWillPop() async {
    if (selectedIndex != 0) {
      setState(() => selectedIndex = 0);
      return false;
    }

    return await showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text("Exit App"),
        content:
        const Text("Are you sure you want to exit?"),
        actions: [
          TextButton(
            onPressed: () =>
                Navigator.pop(context, false),
            child: const Text("Cancel"),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(context, true),
            child: const Text("Exit"),
          ),
        ],
      ),
    ) ??
        false;
  }
}