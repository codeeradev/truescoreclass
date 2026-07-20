import 'dart:async';
import 'dart:convert';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:online_classes/Screens/Student/Bottombar.dart';
import 'package:online_classes/Screens/Student/CardSave.dart';
import 'package:pin_code_fields/pin_code_fields.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class OtpStudentPage extends StatefulWidget {
  const OtpStudentPage({super.key});

  @override
  State<OtpStudentPage> createState() => _OtpStudentPageState();
}

class _OtpStudentPageState extends State<OtpStudentPage> {
  final TextEditingController whatsappOtp = TextEditingController();
  final TextEditingController emailOtp = TextEditingController();
  int seconds = 60;
  Timer? timer;

  @override
  void initState() {
    super.initState();
    startTimer();
  }

  void startTimer() {
    seconds = 60;

    timer?.cancel();
    emailOtp.clear();
    whatsappOtp.clear();
    timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (seconds == 0) {
        timer.cancel();
      } else {
        setState(() {
          seconds--;
        });
      }
    });
  }

  @override
  void dispose() {
    timer?.cancel();
    super.dispose();
  }

  Widget otpField({
    required String title,
    required TextEditingController controller,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        PinCodeTextField(
          appContext: context,
          controller: controller,
          length: 6,
          keyboardType: TextInputType.number,
          animationType: AnimationType.fade,
          cursorColor: Colors.blue,
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          enableActiveFill: true,
          animationDuration: const Duration(milliseconds: 250),
          textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          pinTheme: PinTheme(
            shape: PinCodeFieldShape.box,
            borderRadius: BorderRadius.circular(14),
            fieldHeight: 50,
            fieldWidth: (MediaQuery.of(context).size.width - 100) / 6,
            inactiveColor: Colors.grey.shade300,
            selectedColor: Colors.blue,
            activeColor: Colors.blue,
            activeFillColor: Colors.white,
            selectedFillColor: Colors.white,
            inactiveFillColor: Colors.grey.shade100,
          ),
          onChanged: (value) {},
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final args =
        ModalRoute.of(context)?.settings.arguments as Map<String, dynamic>? ??
            {};

    final String userId = args["user_id"]?.toString() ?? '';
    final String userType = args["user_type"]?.toString() ?? '';
    final String enrollmentId = args["enrollment_id"]?.toString() ?? '';
    final bool isPageValue = args["isPageValue"] ?? true;
    return Scaffold(
      backgroundColor: const Color(0xffF5F7FB),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverAppBar(
            pinned: true,
            floating: false,
            expandedHeight: 280,
            backgroundColor: Colors.blue,
            leading: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            flexibleSpace: LayoutBuilder(
              builder: (context, constraints) {
                final bool collapsed =
                    constraints.biggest.height <= kToolbarHeight + 50;
                return FlexibleSpaceBar(
                  centerTitle: true,
                  title: AnimatedOpacity(
                    duration: const Duration(milliseconds: 250),
                    opacity: collapsed ? 1.0 : 0.0,
                    child: const Text(
                      "OTP Verification",
                      style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  background: Container(
                    decoration: const BoxDecoration(
                      gradient: LinearGradient(
                        colors: [Color(0xff1976D2), Color(0xff42A5F5)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                    ),
                    child: SafeArea(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const SizedBox(height: 30),
                          Lottie.asset('assets/images/otp.json', height: 140),
                          const SizedBox(height: 15),
                          const Text(
                            "Verify Your Account",
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 24,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 30),
                            child: Text(
                              "Enter the 6-digit OTP sent to your WhatsApp and Email.",
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Colors.white.withOpacity(.9),
                                fontSize: 14,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          ),

          /// BODY
          SliverToBoxAdapter(
            child: Padding(
                padding: const EdgeInsets.all(20),
                child: Column(
                  children: [
                    if (isPageValue) ...[
                      otpField(title: "WhatsApp OTP", controller: whatsappOtp),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.chat, color: Colors.green, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Check your WhatsApp or SMS for the verification code.",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 28),
                      otpField(title: "Email OTP", controller: emailOtp),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.email_outlined,
                              color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "Check your email inbox and spam folder for the OTP.",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ] else ...[
                      otpField(title: "Enter OTP", controller: whatsappOtp),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          const Icon(Icons.sms_outlined,
                              color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              "We've sent a 6-digit code to your mobile or email — enter it below.",
                              style: TextStyle(color: Colors.grey.shade600),
                            ),
                          ),
                        ],
                      ),
                    ],
                    const SizedBox(height: 50),
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.blue,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(16),
                          ),
                        ),
                        onPressed: () {
                          if (!isLoading) {
                            verifyOtp(
                                userId: userId.toString(),
                                userType: userType.toString(),
                                enrollmentId: enrollmentId.toString(),
                                isOtpType: isPageValue);
                          }
                        },
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
                                "Verify OTP",
                                style: TextStyle(
                                  fontSize: 17,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Text(
                      seconds == 0
                          ? "Didn't receive the OTP?"
                          : "Resend OTP in 00:${seconds.toString().padLeft(2, '0')}",
                      style:
                          TextStyle(color: Colors.grey.shade600, fontSize: 15),
                    ),
                    if (seconds == 0)
                      TextButton(
                        onPressed: () async {
                          if (!isResendLoading) {
                            await resendOtp(
                                userId: userId.toString(),
                                userType: userType.toString(),
                                enrollmentId: enrollmentId.toString(),
                                isOtpType: isPageValue);
                          }
                        },
                        child: const Text(
                          "Resend OTP",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    const SizedBox(height: 30),
                  ],
                )),
          ),
        ],
      ),
    );
  }

  bool isLoading = false;
  bool isResendLoading = false;

  Future<void> verifyOtp({
    required String userId,
    required String userType,
    required String enrollmentId,
    required bool isOtpType,
  }) async {
    FocusScope.of(context).unfocus();

    if (isOtpType) {
      if (whatsappOtp.text.trim().length != 6) {
        _showSnackBar("Please enter a valid WhatsApp OTP.", isError: true);
        return;
      }

      if (emailOtp.text.trim().length != 6) {
        _showSnackBar("Please enter a valid Email OTP.", isError: true);
        return;
      }
    } else {
      if (whatsappOtp.text.trim().length != 6) {
        _showSnackBar("Please enter a valid mobile or email OTP.",
            isError: true);
        return;
      }
    }
    if (!mounted) return;

    setState(() {
      isLoading = true;
    });
    SharedPreferences preferences = await SharedPreferences.getInstance();

    Map body = {
      "user_id": userId,
      "user_type": userType,
      "email_otp": emailOtp.text.trim(),
      "mobile_otp": whatsappOtp.text.trim(),
    };
    Map bodyLoginOtp = {
      "username": enrollmentId,
      "versionCode": '1',
      "fcm_token": preferences.getString('fcm_token').toString(),
      "otp": whatsappOtp.text.trim(),
    };
    String urlApi = isOtpType ? 'verify-otp' : 'verify-login-otp';
    try {
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/$urlApi"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: isOtpType ? body : bodyLoginOtp,
      );
      print("urlApi---$urlApi");
      print("body---${isOtpType ? body : bodyLoginOtp}");
      print("statusCode---${response.statusCode}");
      if (!mounted) return;
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        print('verifyOtp--${response.body}');
        if (data["status"] == 1 && isOtpType) {
          _showSnackBar(data["msg"], isError: false);
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (_) => Dialog(
              backgroundColor: Colors.transparent,
              insetPadding: const EdgeInsets.all(16),
              child: RegistrationSuccessCard(
                message: data['msg'], // ✅ FIXED KEY
                enrollmentId: data['credentials']['enrollment_id'].toString(),
                // password: data['credentials']['password'].toString(),
              ),
            ),
          );
        } else if (!isOtpType && data['status'].toString() == 'true') {
          await preferences.setString(
            "studentData",
            data['studentData']['enrollmentId'],
          );
          await preferences.setString(
            "token",
            data['studentData']['apiToken'],
          );
          await preferences.setString('type', 'student');
          await preferences.setString(
            "studentname",
            data['studentData']['fullName'],
          );
          await preferences.setString(
            "studentimage",
            data['studentData']['image'].toString(),
          );
          await preferences.setString(
            "studentmail",
            data['studentData']['userEmail'].toString(),
          );
          await preferences.setString(
            "studentph",
            data['studentData']['mobile'].toString(),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => ModernBottomNav()),
          );
          _showSnackBar(
            data['msg'],
            isError: false,
          );
        } else {
          _showSnackBar(data["msg"], isError: true);
        }
      } else {
        _showSnackBar("Something went wrong", isError: true);
      }
    } catch (e) {
      _showSnackBar("Verification failed: $e", isError: true);
    } finally {
      if (!mounted) return;
      setState(() {
        isLoading = false;
      });
    }
  }

  Future<void> resendOtp({
    required String userId,
    required String userType,
    required String enrollmentId,
    required bool isOtpType,
  }) async {
    try {
      if (!mounted) return;

      setState(() {
        isResendLoading = true;
      });
      final response = await http.post(
        Uri.parse("https://truescoreedu.com/api/resend-otp"),
        headers: {"Content-Type": "application/x-www-form-urlencoded"},
        body: {
          "user_id": userId,
          "otp_login": isOtpType?'false': 'true',
          "user_type": 'student',
          if(!isOtpType)
            "username": enrollmentId
        },
      );
      if (!mounted) return;

      final data = jsonDecode(response.body);
      print("resendOtp--$data");
      if (response.statusCode == 200 && data["status"] == 1) {
        _showSnackBar(data["msg"] ?? "OTP resent successfully", isError: false);
        startTimer();
        setState(() {
          emailOtp.clear();
          whatsappOtp.clear();
        });
      } else {
        _showSnackBar(data["msg"] ?? "Failed to resend OTP", isError: true);
      }
    } catch (e) {
      _showSnackBar("Error: $e", isError: true);
    } finally {
      if (!mounted) return;

      setState(() {
        isResendLoading = false;
      });
    }
  }

  void _showSnackBar(String message, {required bool isError}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: isError ? Colors.redAccent : Colors.green,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
  }
}
