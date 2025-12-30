import 'dart:io';

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:online_classes/Screens/Student/purchasedcourses.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../Auth/asktype.dart';
import 'Mydoubtsscreen.dart';
import 'Querystudent.dart';
import 'editprofile.dart';
import 'helps.dart';

class ProfileScreen1 extends StatefulWidget {
  const ProfileScreen1({super.key});

  @override
  State<ProfileScreen1> createState() => _ProfileScreen1State();
}

class _ProfileScreen1State extends State<ProfileScreen1> {
  String userName = "Student Name";
  File? profileImage;
  String image='';

  @override
  void initState() {
    super.initState();
    _loadProfileData();
  }

  /// 🔹 Load Name & Image
  Future<void> _loadProfileData() async {
    final prefs = await SharedPreferences.getInstance();

    setState(() {
      userName = prefs.getString('studentname') ?? "Student Name";

       image = prefs.getString('profileimage').toString();
      // if (imgPath != null) {
      //   profileImage = File(imgPath);
      // }
    });
  }

  /// 🔹 Pick Profile Image
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
    return
      Scaffold(
      backgroundColor: Colors.white,

      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
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
              onTap: (){},
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
                      radius: 55,
                      backgroundColor: Colors.grey.shade200,
                      backgroundImage:
                      image.isNotEmpty ? NetworkImage("https://testora.codeeratech.in/uploads/students/${image}"): null,
                      child: image.isEmpty
                          ? const Icon(Icons.person, size: 55, color: Colors.grey)
                          : null,
                    ),
                  ),
                  // Container(
                  //   padding: const EdgeInsets.all(6),
                  //   decoration: const BoxDecoration(
                  //     color: Colors.blue,
                  //     shape: BoxShape.circle,
                  //   ),
                  //   child: const Icon(Icons.edit, size: 18, color: Colors.white),
                  // )
                ],
              ),
            ),

            const SizedBox(height: 14),

            /// 🔹 NAME
            Text(
              userName,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 24),

            /// 🔹 MENU CARDS
            _profileCard(
              icon: Icons.monetization_on,
              title: "Purchased Courses",
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => purchasedcourses()));
                // Navigate to Doubts Screen
              },
            ),
            _profileCard(
              icon: Icons.support_agent_rounded,
              title: "Help & Support",
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => HelpSupportScreenstudent()));


                // Navigate to Help Screen
              },
            ),
            _profileCard(
              icon: Icons.person,
              title: "Edit Profile",
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => UpdateProfileScreen()));
              },
            ),
            _profileCard(
              icon: Icons.help,
              title: "Any Query",
              onTap: () {
                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => QueryScreen()));
              },
            ),
            _profileCard(
              icon: Icons.document_scanner,
              title: "My Doubts",
              onTap: () {

                Navigator.push(
                    context, MaterialPageRoute(builder: (context) => GetDoubtsScreenstudent()));

                },
            ),
            _profileCard(
              icon: Icons.logout_rounded,
              title: "Logout",
              isLogout: true,
              onTap: () async{
                SharedPreferences pref = await SharedPreferences.getInstance();
                await pref.clear();
                Navigator.pushReplacement(
                    context, MaterialPageRoute(builder: (context) => AskType()));
                // logout logic
              },
            ),
          ],
        ),
      ),
    );
  }

  /// 🔹 Profile Card Widget
  Widget _profileCard({
    required IconData icon,
    required String title,
    required VoidCallback onTap,
    bool isLogout = false,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 10,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: ListTile(
        onTap: onTap,
        leading: Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: isLogout
                ? Colors.red.withOpacity(0.1)
                : Colors.blue.withOpacity(0.1),
            borderRadius: BorderRadius.circular(12),
          ),
          child:
          Icon(
            icon,
            color: isLogout ? Colors.red : Colors.blue,
          ),
        ),
        title:
        Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: isLogout ? Colors.red : Colors.black,
          ),
        ),
        trailing: const Icon(Icons.arrow_forward_ios, size: 16),
      ),
    );
  }
}
