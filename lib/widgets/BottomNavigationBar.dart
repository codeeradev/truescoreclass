import 'package:animated_notch_bottom_bar/animated_notch_bottom_bar/animated_notch_bottom_bar.dart';
import 'package:flutter/material.dart';
import 'package:online_classes/Screens/Community/communityScreen.dart';
import 'package:online_classes/Screens/NotesScreen.dart';

import '../Screens/HomeScreen.dart';
import '../ThemeConstent/themeData.dart';

class BottomNavBar extends StatefulWidget {
  const BottomNavBar({super.key});

  @override
  State<BottomNavBar> createState() => _BottomNavBarState();


}

class _BottomNavBarState extends State<BottomNavBar> {
  final PageController _pageController = PageController(initialPage: 1);
  final NotchBottomBarController _controller = NotchBottomBarController(index: 1);

  final List<Widget> pages = [
    NotesScreen(),
    HomeScreen(),
    CommunnityScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    return WillPopScope(
      onWillPop: () async {
        final shouldExit = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Exit App'),
            content: const Text('Do you really want to exit the app?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel', style: TextStyle(
                    color: Colors.green
                ),),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Yes', style: TextStyle(
                    color: Colors.red
                ),),
              ),

            ],
          ),
        );
        return shouldExit ?? false;
      },
      child: Scaffold(
        body: PageView(
          controller: _pageController,
          physics: const NeverScrollableScrollPhysics(),
          children: pages,
        ),
        extendBody: true,
        bottomNavigationBar: AnimatedNotchBottomBar(
          notchBottomBarController: _controller,
          kBottomRadius: 16.0, // ✅ This is now required
          color: Colors.white,
          showLabel: true,
          // shadowElevation: 5,
          kIconSize: 24,
          bottomBarItems: const [
            BottomBarItem(
              inActiveItem: Icon(Icons.book_outlined, color: AppTheme.iconColor2),
              activeItem: Icon(Icons.book, color: Colors.black87),
            ),
            BottomBarItem(
              inActiveItem: Icon(Icons.home_outlined, color: AppTheme.iconColor2),
              activeItem: Icon(Icons.home, color: Colors.black87),
            ),
            BottomBarItem(
              inActiveItem: Icon(Icons.chat_outlined, color: AppTheme.iconColor2),
              activeItem: Icon(Icons.chat, color: Colors.black87),
            ),
          ],
          onTap: (index) {
            _pageController.jumpToPage(index);
          },
        ),
      ),
    );
  }
}
