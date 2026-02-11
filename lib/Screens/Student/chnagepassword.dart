import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:online_classes/Screens/Auth/asktype.dart';


class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final TextEditingController _otpCtrl = TextEditingController();
  final TextEditingController _passwordCtrl = TextEditingController();
  final TextEditingController _confirmCtrl = TextEditingController();

  bool isLoading = false;
  bool hidePassword = true;

  Future<void> _submit() async {
    final otp = _otpCtrl.text.trim();
    final password = _passwordCtrl.text.trim();
    final confirm = _confirmCtrl.text.trim();

    /// VALIDATIONS
    if (otp.isEmpty || password.isEmpty || confirm.isEmpty) {
      _showSnack("All fields are required", isError: true);
      return;
    }

    if (password.length < 6) {
      _showSnack("Password must be at least 6 characters", isError: true);
      return;
    }

    if (password != confirm) {
      _showSnack("Passwords do not match", isError: true);
      return;
    }

    setState(() => isLoading = true);

    try {
      final res = await http.post(
        Uri.parse("https://truescoreedu.com/api/change-passowrd"),
        headers: {
          "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "otp": otp,
          "password": password,
          "confirm_password": confirm,
        },
      );

      final json = jsonDecode(res.body);
      print(json);
      print(res.statusCode);

      if (res.statusCode == 200 && json["status"] == true) {
        _showSnack(
          json["message"] ?? "Password changed successfully",
          isError: false,
        );

        /// GO BACK TO LOGIN
        Future.delayed(const Duration(seconds: 1), () {
          Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=>AskType()));
        });
      } else {
        _showSnack(
          json["message"] ?? "Failed to change password",
          isError: true,
        );
      }
    } catch (e) {
      _showSnack("Network error. Try again.", isError: true);
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
        title: const Text("Reset Password"),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 20),

              /// ICON
              Center(
                child: CircleAvatar(
                  radius: 42,
                  backgroundColor: Colors.blue.withOpacity(0.1),
                  child: const Icon(
                    Icons.lock_outline,
                    size: 40,
                    color: Colors.blue,
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// TITLE
              const Text(
                "Create New Password",
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),

              const SizedBox(height: 6),

              const Text(
                "Enter OTP and create a new password for your account.",
                style: TextStyle(color: Colors.black54),
              ),

              const SizedBox(height: 24),

              /// OTP FIELD
              TextField(
                controller: _otpCtrl,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  labelText: "OTP",
                  prefixIcon: const Icon(Icons.lock_clock),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// PASSWORD
              TextField(
                controller: _passwordCtrl,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: "New Password",
                  prefixIcon: const Icon(Icons.lock),
                  suffixIcon: IconButton(
                    icon: Icon(
                      hidePassword
                          ? Icons.visibility_off
                          : Icons.visibility,
                    ),
                    onPressed: () =>
                        setState(() => hidePassword = !hidePassword),
                  ),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              /// CONFIRM PASSWORD
              TextField(
                controller: _confirmCtrl,
                obscureText: hidePassword,
                decoration: InputDecoration(
                  labelText: "Confirm Password",
                  prefixIcon: const Icon(Icons.lock_outline),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              /// SUBMIT BUTTON
              SizedBox(
                width: double.infinity,
                height: 52,
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
                    "Change Password",
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
      ),
    );
  }
}
