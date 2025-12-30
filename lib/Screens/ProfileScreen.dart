import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ProfileScreen extends StatefulWidget {

  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String userName = "Student Name";
  File? profileImage;

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// 🔹 Load user name & image
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      userName = prefs.getString('studentname') ?? "Student Name";
      final imgPath = prefs.getString('profile_image');
      if (imgPath != null) profileImage = File(imgPath);
    });
  }

  /// 🔹 Pick profile image
  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final XFile? image =
    await picker.pickImage(source: ImageSource.gallery, imageQuality: 70);

    if (image != null) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('profile_image', image.path);

      setState(() {
        profileImage = File(image.path);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF4F7FF),

      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          "Profile",
          style: TextStyle(color: Colors.black),
        ),
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black),
      ),

      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [

            /// 🔵 PROFILE IMAGE
            GestureDetector(
              onTap: _pickImage,
              child: Stack(
                alignment: Alignment.bottomRight,
                children: [

                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.blue, width: 3),
                    ),
                    child: CircleAvatar(
                      radius: 56,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                      profileImage != null ? FileImage(profileImage!) : null,
                      child: profileImage == null
                          ? const Icon(Icons.person,
                          size: 56, color: Colors.grey)
                          : null,
                    ),
                  ),

                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: Colors.blue,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.edit,
                        size: 18, color: Colors.white),
                  )
                ],
              ),
            ),

            const SizedBox(height: 14),

            /// 🔹 USER NAME
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 30),

            /// 🔹 PREMIUM CARDS
            premiumProfileCard(
              icon: Icons.help_outline_rounded,
              title: "Ask a Doubt",
              subtitle: "Get help from mentors",
              onTap: () {},
            ),

            premiumProfileCard(
              icon: Icons.support_agent_rounded,
              title: "Help & Support",
              subtitle: "24×7 assistance",
              startColor: const Color(0xFF0EA5E9),
              endColor: const Color(0xFF38BDF8),
              onTap: () {},
            ),

            premiumProfileCard(
              icon: Icons.info_outline_rounded,
              title: "About App",
              subtitle: "Version & information",
              startColor: const Color(0xFF22C55E),
              endColor: const Color(0xFF4ADE80),
              onTap: () {},
            ),

            premiumProfileCard(
              icon: Icons.logout_rounded,
              title: "Logout",
              subtitle: "Sign out from account",
              startColor: const Color(0xFFEF4444),
              endColor: const Color(0xFFF87171),
              onTap: () {
                // Logout logic here
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 PREMIUM CARD WIDGET
  Widget premiumProfileCard({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
    Color startColor = const Color(0xFF2563EB),
    Color endColor = const Color(0xFF3B82F6),
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(22),
          boxShadow: [

            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 16,
              offset: const Offset(0, 8),
            ),

          ],
        ),
        child:
        Row(
          children: [

            /// ICON
            Container(
              height: 52,
              width: 52,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [startColor, endColor],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(icon, color: Colors.white, size: 26),
            ),

            const SizedBox(width: 16),

            /// TEXT
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  if (subtitle != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ]
                ],
              ),
            ),

            Icon(
              Icons.arrow_forward_ios_rounded,
              size: 16,
              color: Colors.grey.shade400,
            )
          ],
        ),
      ),
    );
  }
}
