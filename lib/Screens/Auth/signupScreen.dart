import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:online_classes/ThemeConstent/themeData.dart';
import 'dart:async';

import '../../Splash/Signature.dart';
import '../../widgets/BottomNavigationBar.dart';



class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> with TickerProviderStateMixin {
  final TextEditingController nameController = TextEditingController();
  final TextEditingController emailController = TextEditingController();
  final TextEditingController numberController = TextEditingController();
  final PageController _imageController = PageController(viewportFraction: 0.45);

  bool loading = false;

  int _currentPage = 0;
  late AnimationController _fieldController;
  late AnimationController _buttonController;

  /// API register api url
  final String _baseUrl = 'https://digiacademy.onrender.com/digi/register';




  final List<String> _imageUrls = [
    'https://picsum.photos/id/1041/400/300',
    'https://picsum.photos/id/1050/400/300',
    'https://picsum.photos/id/1062/400/300',
    'https://picsum.photos/id/1074/400/300',
  ];
  Future<void> registerUser({

    required String firstName,
    required String lastName,
    required String identifier,
    required String password,
    required BuildContext context,

  }) async {
    try {
      setState(() {
        loading=true;

      });

      final response = await http.post(
        Uri.parse(_baseUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          "Name": firstName,
          "email": identifier,
          "password": password,
        }),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {

        setState(() {
          loading=false;

        });
        debugPrint('Registration successful: ${response.body}');
        Navigator.push(context, MaterialPageRoute(builder: (context)=> BottomNavBar()));
      } else {

        setState(() {
          loading=false;

        });
        debugPrint('Failed to register: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {

      setState(() {
        loading=false;

      });
      debugPrint('Error during registration: $e');
    }
  }

  @override
  void initState() {
    super.initState();
    _fieldController = AnimationController(vsync: this, duration: const Duration(milliseconds: 800))..repeat(reverse: true);
    _buttonController = AnimationController(vsync: this, duration: const Duration(seconds: 2))..repeat(reverse: true);

    Timer.periodic(const Duration(seconds: 2), (timer) {
      if (_imageController.hasClients) {
        _currentPage = (_currentPage + 1) % _imageUrls.length;
        _imageController.animateToPage(
          _currentPage,
          duration: const Duration(milliseconds: 500),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _imageController.dispose();
    _fieldController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _onRegister() {
    final name = nameController.text.trim();
    final email = emailController.text.trim();
    final number = numberController.text.trim();
    if (name.isEmpty || email.isEmpty || number.isEmpty || number.length != 10) {
      String errorMessage;

      if (name.isEmpty || email.isEmpty || number.isEmpty) {
        errorMessage = "Please fill all fields";
      } else if (number.length != 10) {
        errorMessage = "Mobile number must be 10 digits";
      } else {
        errorMessage = "Invalid input";
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(errorMessage)),
      );
      return;
    }


    registerUser(
      firstName: name,
      lastName: email,
      identifier: "+91$number",
      password: "1234",
      context: context,

    );
  }

  @override
  Widget build(BuildContext context) {
    return
     Scaffold(

      body: loading==true ? Center(child: CircularProgressIndicator( color: Colors.blue,)):SignatureBackground(
        opacity: 0.25,
        useDarkWaves: false,
        gradientColors: [AppTheme.primeryColor, Colors.teal],
        child:
        SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                const SizedBox(height: 24),
                const Text('Create Account on DigiAcademyPro', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 94),
                _buildField('Name', nameController),
                const SizedBox(height: 24),
                _buildField('Email', emailController, keyboardType: TextInputType.emailAddress),
                const SizedBox(height: 24),
                _buildField('Phone Number', numberController, keyboardType: TextInputType.phone),
                const SizedBox(height:226),
                ScaleTransition(
                  scale: Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut)),
                  child: SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: _onRegister,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primeryColor,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      ),
                      child: const Text('Register', style: TextStyle(color: Colors.black, fontSize: 16)),
                    ),
                  ),
                ),
                const SizedBox(height: 100),
                // PageView & Signin Link remain unchanged...
              ],
            ),
          ),
        ),
      ),
    );

  }

  Widget _buildField(String label, TextEditingController controller, {TextInputType keyboardType = TextInputType.text}) {
    return ScaleTransition(
      scale: Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _fieldController, curve: Curves.easeInOut)),
      child: Material(
        elevation: 3,
        shadowColor: Colors.grey,
        borderRadius: BorderRadius.circular(20),
        child: TextField(
          controller: controller,
          keyboardType: keyboardType,
          decoration: InputDecoration(
            labelText: label,
            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
          ),
        ),
      ),
    );
  }
}
