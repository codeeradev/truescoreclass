import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import 'chnagepassword.dart';

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final TextEditingController _emailCtrl = TextEditingController();
  bool isLoading = false;

  Future<void> _submit() async {
    final email = _emailCtrl.text.trim();

    if (email.isEmpty) {
      _showSnack("Please enter email address", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("https://truescoreedu.com/api/forgot-passowrd"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "username": email, // 👈 API KEY
        },
      );

      final json = jsonDecode(res.body);
      print(json);

      if (res.statusCode == 200 && json["status"] == true) {
        _showSnack(
          json["message"] ?? "Password reset link sent to your email",
          isError: false,
        );
        Navigator.push(context, MaterialPageRoute(builder: (context)=>ChangePasswordScreen()));
        //Navigator.pop(context);
      } else {
        _showSnack(
          json["message"] ?? "Failed to send reset link",
          isError: true,
        );
      }
    } catch (e) {
      _showSnack("Network error. Please try again.", isError: true);
    } finally {
      setState(() => isLoading = false);
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: isError ? Colors.red : Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Forgot Password"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 30),

            /// ICON
            Center(
              child: CircleAvatar(
                radius: 40,
                backgroundColor: Colors.blue.withOpacity(0.1),
                child: const Icon(
                  Icons.lock_reset,
                  color: Colors.blue,
                  size: 40,
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// TITLE
            const Text(
              "Forgot your password?",
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),

            const SizedBox(height: 8),

            const Text(
              "Enter your registered email address. We will send you a password reset link.",
              style: TextStyle(color: Colors.black54),
            ),

            const SizedBox(height: 24),

            /// EMAIL FIELD
            TextField(
              controller: _emailCtrl,
              keyboardType: TextInputType.emailAddress,
              decoration: InputDecoration(
                labelText: "Email Address",
                prefixIcon: const Icon(Icons.email_outlined),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),

            const SizedBox(height: 30),

            /// SUBMIT BUTTON
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: isLoading ? null : _submit,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: isLoading
                    ? const SizedBox(
                  width: 22,
                  height: 22,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
                    : const Text(
                  "Send Reset Link",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
