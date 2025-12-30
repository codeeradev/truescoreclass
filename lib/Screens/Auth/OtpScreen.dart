import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:lottie/lottie.dart';

import '../../widgets/BottomNavigationBar.dart'; // Add this to pubspec.yaml

class OTPPage extends StatefulWidget {
  const OTPPage({Key? key}) : super(key: key);

  @override
  State<OTPPage> createState() => _OTPPageState();
}

class _OTPPageState extends State<OTPPage> {
  final TextEditingController phoneController = TextEditingController();
  final List<TextEditingController> otpControllers =
  List.generate(6, (index) => TextEditingController());

  FocusNode? currentFocus;

  @override
  void initState() {
    super.initState();
    currentFocus = FocusNode();
  }

  Widget _buildOtpBox(int index) {
    return Container(
      width: 45,

      height: 60,
      alignment: Alignment.center,
      margin: const EdgeInsets.symmetric(horizontal: 6),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade400),
      ),
      child: TextField(
        controller: otpControllers[index],
        autofocus: index == 0,
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        maxLength: 1,
        style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
        decoration: const InputDecoration(
          border: InputBorder.none,
          counterText: '',
        ),
        onChanged: (value) {
          if (value.isNotEmpty && index < 5) {
            FocusScope.of(context).nextFocus();
          } else if (value.isEmpty && index > 0) {
            FocusScope.of(context).previousFocus();
          }
        },
      ),
    ).animate().fadeIn(duration: 500.ms).slideY(begin: 0.5, end: 0);
  }

  @override
  Widget build(BuildContext context) {
    return
      Scaffold(
      appBar: AppBar(title: const Text('Enter OTP')),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(20.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
        
              const SizedBox(height: 30),
              const Text('Enter 6-digit OTP'),
              const SizedBox(height: 10),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(6, _buildOtpBox),
              ),
              const SizedBox(height: 40),
              ElevatedButton(
                onPressed: () {
                  final otp = otpControllers.map((c) => c.text).join();
                  print('OTP: $otp');
                  Navigator.pushReplacement(context, MaterialPageRoute(builder: (context)=> BottomNavBar()));
                  // Add your verification logic here
                },
                child: const Text('Verify'),
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                ),
              ),
              SizedBox(height: 30,),
              Container(
                child: Lottie.asset(
                  'assets/images/otp.json',
                  width: double.maxFinite,
                  height: MediaQuery.of(context).size.height*0.2,
                  fit: BoxFit.contain,
        
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
