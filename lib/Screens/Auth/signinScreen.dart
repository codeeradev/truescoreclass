import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../Splash/Signature.dart';
import '../../ThemeConstent/themeData.dart';
import '../Student/Bottombar.dart';
import '../Student/DasgBoradScreen.dart';
import '../Student/RegisterStudent.dart';
import '../Student/forgetpassword.dart';
import '../Teachers/screens/TeacherDashboardScreen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool isLoading = false;

  final PageController _imageController = PageController(viewportFraction: 0.5);
  int _currentPage = 0;

  final List<String> _imageUrls = [
    'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f',
    'https://images.unsplash.com/photo-1529070538774-1843cb3265df',
    'https://images.unsplash.com/photo-1588072432836-e10032774350',
    'https://images.unsplash.com/photo-1509062522246-3755977927d7',
    'https://images.unsplash.com/photo-1513258496099-48168024aec0',
  ];

  @override
  void initState() {
    super.initState();
    Timer.periodic(const Duration(seconds: 3), (timer) {
      if (_imageController.hasClients) {
        _currentPage = (_currentPage + 1) % _imageUrls.length;
        _imageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
      }
    });
  }

  @override
  void dispose() {
    _imageController.dispose();
    emailController.dispose();
    passwordController.dispose();
    super.dispose();
  }

  Future<void> signin() async {
    print('st');
    SharedPreferences preferences = await SharedPreferences.getInstance();

    final response = await http.post(
      Uri.parse('https://truescoreedu.com/api/login'),
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
      },
      body: {
        "username": emailController.text.trim(),
        "password": passwordController.text.trim(),
        "token": "sadfsa",
        "versionCode": "1",
      },
    );

    //print(response.body);
    final data = jsonDecode(response.body);
    print(data);
    print(response.statusCode);


    if (response.statusCode == 200) {
    //  showSnack(context,data['msg'].toString());

      await preferences.setString("studentData", data['studentData']['enrollmentId']);
      await preferences.setString("token", data['studentData']['apiToken']);
      await preferences.setString('type', 'student');
      await preferences.setString("studentname", data['studentData']['fullName']);
      await preferences.setString("studentimage", data['studentData']['image'].toString());
      await preferences.setString("studentmail", data['studentData']['userEmail'].toString());
      await preferences.setString("studentph", data['studentData']['mobile'].toString());





      print(data['studentData']['enrollmentId']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ModernBottomNav()),
      );
    }else{
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red.shade700,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        margin: const EdgeInsets.fromLTRB(16, 0, 16, 24),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              Color(0xFFE8F0FE),
              Color(0xFFF5F9FF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Container(height: double.maxFinite,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 12),

                  // Back button (kept your original)
                  InkWell(
                    onTap: () => Navigator.pop(context),
                    borderRadius: BorderRadius.circular(12),
                    child: const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: Icon(Icons.arrow_back_rounded, size: 32, color: Color(0xFF1E40AF)),
                    ),
                  ),

                  const SizedBox(height: 32),

                  const Text(
                    "Welcome to TrueScore",
                    style: TextStyle(
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF1E40AF),
                      letterSpacing: -0.5,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Sign in to continue learning",
                    style: TextStyle(
                      fontSize: 16,
                      color: Colors.grey.shade700,
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Glassmorphic-like card
                  Container(
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(32),
                      border: Border.all(color: Colors.blue.shade100, width: 1.2),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.blue.shade200.withOpacity(0.18),
                          blurRadius: 32,
                          offset: const Offset(0, 16),
                        ),
                        BoxShadow(
                          color: Colors.white.withOpacity(0.7),
                          blurRadius: 20,
                          offset: const Offset(-8, -8),
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        _buildTextField(
                          controller: emailController,
                          hint: "Username or ID",
                          icon: Icons.alternate_email_rounded,
                        ),
                        const SizedBox(height: 16),

                        _buildTextField(
                          controller: passwordController,
                          hint: "Password",
                          icon: Icons.lock_outline_rounded,
                          obscureText: _obscurePassword,
                          isPassword: true,
                          onVisibilityTap: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),

                        const SizedBox(height: 32),

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: ElevatedButton(
                            onPressed: isLoading ? null : signin,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: const Color(0xFF2563EB),
                              foregroundColor: Colors.white,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                              elevation: 8,
                              shadowColor: Colors.blue.shade400.withOpacity(0.5),
                            ),
                            child: isLoading
                                ? const SizedBox(
                              height: 24,
                              width: 24,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 3,
                              ),
                            )
                                : const Text(
                              "Sign In",
                              style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ),

                        const SizedBox(height: 24),

                        SizedBox(
                          width: double.infinity,
                          height: 58,
                          child: OutlinedButton(
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(builder: (_) => SelfRegistrationScreen1()),
                              );
                            },
                            style: OutlinedButton.styleFrom(
                              side: const BorderSide(color: Color(0xFF2563EB), width: 2),
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            ),
                            child: const Text(
                              "Register Now",
                              style: TextStyle(
                                color: Color(0xFF2563EB),
                                fontSize: 17,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>ForgotPasswordScreen()));
                            },
                            child: const Text(
                              "Forgot Password?",
                              style: TextStyle(color: Colors.blue),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 48),

                  // Image carousel – kept but styled better
                  // SizedBox(
                  //   height: 180,
                  //   child: PageView.builder(
                  //     controller: _imageController,
                  //     itemCount: _imageUrls.length,
                  //     itemBuilder: (context, index) {
                  //       return AnimatedBuilder(
                  //         animation: _imageController,
                  //         builder: (context, child) {
                  //           double value = 0.0;
                  //           if (_imageController.position.haveDimensions) {
                  //             value = _imageController.page! - index;
                  //           }
                  //           final scale = (1 - value.abs() * 0.28).clamp(0.72, 1.0);
                  //           final yOffset = value.abs() < 0.5 ? 12.0 : -8.0;
                  //
                  //           return Transform.translate(
                  //             offset: Offset(0, yOffset),
                  //             child: Transform.scale(
                  //               scale: scale,
                  //               child: Padding(
                  //                 padding: const EdgeInsets.symmetric(horizontal: 8),
                  //                 child: ClipRRect(
                  //                   borderRadius: BorderRadius.circular(24),
                  //                   child: Image.network(
                  //                     _imageUrls[index],
                  //                     fit: BoxFit.cover,
                  //                   ),
                  //                 ),
                  //               ),
                  //             ),
                  //           );
                  //         },
                  //       );
                  //     },
                  //   ),
                  // ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscureText = false,
    bool isPassword = false,
    VoidCallback? onVisibilityTap,
  }) {
    return TextField(
      controller: controller,
      obscureText: obscureText,
      style: const TextStyle(
        color: Color(0xFF1E3A8A),
        fontSize: 16,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(color: Colors.grey.shade500, fontSize: 15),
        prefixIcon: Icon(icon, color: const Color(0xFF3B82F6)),
        suffixIcon: isPassword
            ? IconButton(
          icon: Icon(
            obscureText ? Icons.visibility_off_rounded : Icons.visibility_rounded,
            color: const Color(0xFF3B82F6),
          ),
          onPressed: onVisibilityTap,
        )
            : null,
        filled: true,
        fillColor: const Color(0xFFF0F7FF),
        contentPadding: const EdgeInsets.symmetric(vertical: 18, horizontal: 20),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: BorderSide(color: Colors.blue.shade100),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(20),
          borderSide: const BorderSide(color: Color(0xFF2563EB), width: 1.8),
        ),
      ),
    );
  }
}