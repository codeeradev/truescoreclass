import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../Splash/Signature.dart';
import '../../ThemeConstent/themeData.dart';
import '../Student/DasgBoradScreen.dart';
import '../Student/forgetpassword.dart';
import '../Teachers/screens/TeacherDashboardScreen.dart';
import 'asktype.dart';
import 'OtpScreen.dart';
import 'signupScreen.dart';

class TeacherSigninScreen extends StatefulWidget {
  const TeacherSigninScreen({super.key});

  @override
  State<TeacherSigninScreen> createState() => _TeacherSigninScreenState();
}

class _TeacherSigninScreenState extends State<TeacherSigninScreen> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();

  bool _obscurePassword = true;
  bool isLoading = false;

  final PageController _imageController = PageController(viewportFraction: 0.52);
  int _currentPage = 0;

  final List<String> _imageUrls = [
    "https://images.unsplash.com/photo-1588072432836-e10032774350",
    "https://images.unsplash.com/photo-1529070538774-1843cb3265df",
    "https://images.unsplash.com/photo-1524995997946-a1c2e315a42f",
    "https://images.unsplash.com/photo-1517849845537-4d257902454a",
    "https://images.unsplash.com/photo-1509062522246-3755977927d7",
  ];

  @override
  void initState() {
    super.initState();
    Timer.periodic( Duration(seconds: 3), (timer) {
      if (_imageController.hasClients) {
        _currentPage = (_currentPage + 1) % _imageUrls.length;
        _imageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 900),
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

  Future<void> _loginTeacher() async {
    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
      _showError("Please enter username and password");
      return;
    }

    setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://truescoreedu.com/api/user-login'),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "username": emailController.text.trim(),
          "password": passwordController.text.trim(),
          "role": "3", // Teacher role
        },
      );

      final data = json.decode(response.body);

      if (response.statusCode == 200 && data['data'] != null) {
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString('id', data['data']['id'].toString());
        await prefs.setString('token', data['data']['apiToken'].toString());
        await prefs.setString('type', 'teacher');
        await prefs.setString('teachername', data['data']['name']?.toString() ?? '');
        await prefs.setString('teachermail', data['data']['email']?.toString() ?? '');
        await prefs.setString('teacherno', data['data']['phone']?.toString() ?? '');

        if (!mounted) return;
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => const TeacherDashboardScreen()),
        );
      } else {
        _showError(data['message'] ?? "Invalid credentials");
      }
    } catch (e) {
      _showError("Something went wrong. Please try again.");
    } finally {
      if (mounted) setState(() => isLoading = false);
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
              Color(0xFFE8F0FE), // very soft blue
              Color(0xFFF5F9FF),
              Color(0xFFFFFFFF),
            ],
          ),
        ),
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const SizedBox(height: 8),

                // Back button
                InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () {
                    Navigator.pushReplacement(
                      context,
                      MaterialPageRoute(builder: (_) => const AskType()),
                    );
                  },
                  child: const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Icon(
                      Icons.arrow_back_rounded,
                      size: 32,
                      color: Color(0xFF1E40AF),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                const Text(
                  "Welcome Teacher",
                  style: TextStyle(
                    fontSize: 34,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF1E40AF),
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  "Sign in to manage your classes",
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.grey.shade700,
                  ),
                ),

                const SizedBox(height: 48),

                // Main card
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
                        hint: "Username or Email",
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
                          onPressed: isLoading ? null : _loginTeacher,
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
                            "Sign In as Teacher",
                            style: TextStyle(
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

                // Image carousel


                const SizedBox(height: 40),
              ],
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