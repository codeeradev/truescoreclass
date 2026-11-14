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
    int selectedIndex = 0 ;

    ModernBottomNav({super.key, this.selectedIndex=0});

  @override
  State<ModernBottomNav> createState() => _ModernBottomNavState();
}

class _ModernBottomNavState extends State<ModernBottomNav> {

  // List<dynamic> doubts = [];
  int unreadCount = 0;

  final List<Widget> pages = [
    StudentDashboardScreen(),
    MyOnlyPurchased(),
    CourseSearchScreen(),
    GetDoubtsScreenstudent(),
    ProfileScreen1(),
  ];

  bool get showFab => widget.selectedIndex == 0 || widget.selectedIndex == 1;

  bool get showBottomBar =>widget. selectedIndex != 2;

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
        print('json---$json');
        if (json['status'] == 1) {
          //
          // /// 🔥 GET SAVED SEEN COUNT
          // int seenCount = prefs.getInt("seen_doubts_count") ?? 0;
          //
          // /// 🔥 CALCULATE UNREAD
          // int newUnread = data.length - seenCount;
          // if (newUnread < 0) newUnread = 0;

          setState(() {
            // doubts = data;
            unreadCount = json['unread_count'] ?? 0;
          });
        }
      }
    } catch (e) {
      debugPrint("Error fetching doubts: $e");
    }
  }

  @override
  void dispose() {
    super.dispose();
    SecureScreen.disable();
  }

  //---------------- UI ----------------//
  @override
  Widget build(BuildContext context) {
    final bool isKeyboardOpen = MediaQuery.of(context).viewInsets.bottom > 0;

    return WillPopScope(
      onWillPop: _onWillPop,
      child: Scaffold(
        resizeToAvoidBottomInset: false,
        backgroundColor: Colors.white,

        // body: IndexedStack(
        //   index: selectedIndex,
        //   children: pages,
        // ),
        body: pages[widget.selectedIndex],

        /// FAB
        ///
        floatingActionButton: isKeyboardOpen || !showBottomBar
            ? null
            : FloatingActionButton(
                heroTag: null,
                backgroundColor: Colors.black,
                elevation: 8,
                onPressed: () {
                  setState(() => widget.selectedIndex = 2);
                },
                child: const Icon(Icons.search, color: Colors.white, size: 28),
              ),

        floatingActionButtonLocation: FloatingActionButtonLocation.centerDocked,

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
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _navItem(Icons.home_rounded, "Home", 0),
                      _navItem(Icons.monetization_on, "Purchased", 1),
                      const SizedBox(width: 40),
                      _navItem(Icons.help, "Doubts", 3),
                      _navItem(Icons.person_rounded, "Profile", 4),
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  //---------------- NAV ITEM ----------------//
  Widget _navItem(IconData icon, String label, int index) {
    final bool isSelected = widget.selectedIndex == index;
    final bool showBadge = index == 3 && unreadCount > 0;
    return InkWell(
      onTap: () async {
        // /// 🔥 RESET COUNT WHEN OPEN DOUBTS
        if (index == 3) {
          // final prefs = await SharedPreferences.getInstance();
          // await prefs.setInt("seen_doubts_count", doubts.length);
          //
          // setState(() {
          //   unreadCount = 0;
          // });
          fetchDoubts();
        }

        setState(() => widget.selectedIndex = index);
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
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      unreadCount > 99 ? "99+" : unreadCount.toString(),
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
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }

  //---------------- BACK BUTTON ----------------//
  Future<bool> _onWillPop() async {
    if (widget.selectedIndex != 0) {
      setState(() => widget.selectedIndex = 0);
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
