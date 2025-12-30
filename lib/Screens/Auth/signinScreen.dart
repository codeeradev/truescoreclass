import 'dart:async';
import 'dart:math';
import 'package:flutter/material.dart';
import 'package:online_classes/Screens/Auth/OtpScreen.dart';
import 'package:online_classes/Screens/Auth/signupScreen.dart';
import 'package:online_classes/widgets/BottomNavigationBar.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

import '../../Splash/Signature.dart';
import '../../ThemeConstent/themeData.dart';
import '../Student/Bottombar.dart';
import '../Student/DasgBoradScreen.dart';
import '../Student/RegisterStudent.dart';
import '../Teachers/screens/TeacherDashboardScreen.dart';

class SigninScreen extends StatefulWidget {
  const SigninScreen({super.key});

  @override
  State<SigninScreen> createState() => _SigninScreenState();
}

class _SigninScreenState extends State<SigninScreen> with TickerProviderStateMixin {
  final TextEditingController emailController = TextEditingController();
  final TextEditingController passwordController = TextEditingController();
  final PageController _imageController = PageController(viewportFraction: 0.45);

  bool _obscurePassword = true;
  bool _showParticles = false;
  int _currentPage = 0;
  late AnimationController _particleController;
  late AnimationController _fieldController;
  late AnimationController _buttonController;
  List<Offset> _particles = [];
  Random _random = Random();


  final List<String> _imageUrls = [
    // Books & Study Desk
    'https://images.unsplash.com/photo-1524995997946-a1c2e315a42f',
    //'https://images.unsplash.com/photo-1519681393784-d120267933ba',

    // Students studying
    //'https://images.unsplash.com/photo-1523050854058-8df90110c9f1',
    'https://images.unsplash.com/photo-1529070538774-1843cb3265df',

    // Classroom & Learning
    'https://images.unsplash.com/photo-1588072432836-e10032774350',
    'https://images.unsplash.com/photo-1509062522246-3755977927d7',

    // Notes, laptop, education
    'https://images.unsplash.com/photo-1513258496099-48168024aec0',
    'https://images.unsplash.com/photo-1491841651911-c44c30c34548',
  ];


  Future<void> loginUser() async {
    SharedPreferences preferences = await SharedPreferences.getInstance();


    if (emailController.text.trim().isEmpty || passwordController.text.isEmpty) {
     // _showSnackBar("Please fill all fields", isError: true);
      return;
    }

   // setState(() => isLoading = true);

    try {
      final response = await http.post(
        Uri.parse('https://testora.codeeratech.in/api/user-login'),
        headers: {        "Content-Type": "application/x-www-form-urlencoded",
        },
        body: {
          "username": emailController.text.trim(), // Accepts mobile or email
          "password": passwordController.text,
          "role":"3"
        },
      );

      final data = json.decode(response.body);
      print(response.body);
      print(response.statusCode);

      if (response.statusCode == 200) {
       // _showSnackBar("Login Successful! Welcome back", isError: false);
        await preferences.setString('id', data['data']['id'].toString());
        await preferences.setString('token', data['data']['apiToken'].toString());
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => TeacherDashboardScreen()),
        );


        // Navigate to HomeScreen after successful login
        // Navigator.pushReplacement(
        //   context,
        //   MaterialPageRoute(builder: (context) => const HomeScreen()),
        // );
      } else {
       // _showSnackBar(data['message'] ?? "Invalid credentials", isError: true);
      }
    } catch (e) {
     // _showSnackBar("Network error. Please try again.", isError: true);
    } finally {
     // setState(() => isLoading = false);
    }
  }

  Future<void> signin() async {
    print('st');
    SharedPreferences preferences = await SharedPreferences.getInstance();

    final response = await http.post(
      Uri.parse('https://testora.codeeratech.in/api/login'),
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
      showSnack(context,data['msg'].toString());

      await preferences.setString("studentData", data['studentData']['enrollmentId']);
      await preferences.setString("token", data['studentData']['apiToken']);
      await preferences.setString('type', 'student');
      await preferences.setString("studentname", data['studentData']['fullName']);
      await preferences.setString("studentimage", data['studentData']['image'].toString());



      print(data['studentData']['enrollmentId']);

      Navigator.pushReplacement(
        context,
        MaterialPageRoute(builder: (context) => ModernBottomNav()),
      );
    }else{
    }
  }
  void showSnack(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: Duration(seconds: 2),
      ),
    );
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
    _particleController.dispose();
    _fieldController.dispose();
    _buttonController.dispose();
    super.dispose();
  }

  void _onSignIn() {

    final email = emailController.text.trim();
    final password = passwordController.text.trim();
    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter all fields")),
      );
      return;
    }
    signin();

  }

  void _startParticles() {
    setState(() {
      _showParticles = true;
      _particles = List.generate(200, (_) => Offset(_random.nextDouble() * MediaQuery.of(context).size.width, _random.nextDouble() * MediaQuery.of(context).size.height));
    });
    _particleController.forward(from: 0);
    Future.delayed(const Duration(seconds: 2), () {
      setState(() => _showParticles = false);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body:
      SignatureBackground(
        opacity: 0.25,
        useDarkWaves: false,
        gradientColors: [AppTheme.primeryColor, Colors.teal],

        child: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 24),

                    const Text('Welcome to Testora', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                    const SizedBox(height: 123),
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _fieldController, curve: Curves.easeInOut)),
                      child: Material(
                        elevation: 3,
                        shadowColor: Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                        child: TextField(
                          controller: emailController,
                          keyboardType: TextInputType.emailAddress,
                          decoration: const InputDecoration(
                            labelText: 'Username',
                            border: OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.03).animate(CurvedAnimation(parent: _fieldController, curve: Curves.easeInOut)),
                      child: Material(
                        elevation: 3,
                        shadowColor: Colors.grey,
                        borderRadius: BorderRadius.circular(20),
                        child: TextField(
                          controller: passwordController,
                          obscureText: _obscurePassword,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            border: const OutlineInputBorder(borderRadius: BorderRadius.all(Radius.circular(20))),
                            suffixIcon: IconButton(
                              icon: Icon(_obscurePassword ? Icons.visibility_off : Icons.visibility),
                              onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                            ),
                          ),
                        ),
                      ),
                    ),
                    // Align(
                    //   alignment: Alignment.centerRight,
                    //   child: TextButton(
                    //     onPressed: () {},
                    //     child: const Text('Forgot Password?'),
                    //   ),
                    // ),
                    const SizedBox(height: 46),
                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut)),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _onSignIn,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: AppTheme.primeryColor,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Sign In', style: TextStyle(color: Colors.black, fontSize: 16)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 26),

                    ScaleTransition(
                      scale: Tween(begin: 1.0, end: 1.05).animate(CurvedAnimation(parent: _buttonController, curve: Curves.easeInOut)),
                      child: SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: (){
                            Navigator.push(context, MaterialPageRoute(builder: (context)=>SelfRegistrationScreen1()));
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.black,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child:  Text(' Register ' , style: TextStyle(color: Colors.white, fontSize: 16,fontWeight: FontWeight.bold)),
                        ),
                      ),
                    ),
                    const SizedBox(height: 100),
                    SizedBox(
                      height: 170, // Increased from 140 to avoid clipping
                      child: PageView.builder(
                        controller: _imageController,
                        itemCount: _imageUrls.length,
                        clipBehavior: Clip.none, // 👈 Prevents clipping of translated widgets
                        itemBuilder: (context, index) {
                          return AnimatedBuilder(
                            animation: _imageController,
                            builder: (context, child) {
                              double value = 0.0;
                              if (_imageController.position.haveDimensions) {
                                value = _imageController.page! - index;
                              }

                              final scale = (1 - value.abs() * 0.3).clamp(0.7, 1.0);
                              final yOffset = value.abs() < 0.5 ? 20.0 : -10.0;

                              return Transform.translate(
                                offset: Offset(0, yOffset),
                                child: Transform.scale(
                                  scale: scale,
                                  alignment: Alignment.center,
                                  child: child,
                                ),
                              );
                            },
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 6.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(20),
                                child: Image.network(
                                  _imageUrls[index],
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                          );
                        },
                      ),
                    ),



                    const SizedBox(height: 20),
                    // Row(
                    //   mainAxisAlignment: MainAxisAlignment.center,
                    //   children: [
                    //     const Text("Don't have an account?"),
                    //     TextButton(
                    //       onPressed: () {
                    //         Navigator.push(
                    //           context,
                    //           MaterialPageRoute(builder: (context) => const RegisterScreen()),
                    //         );
                    //       },
                    //       child: const Text('Sign up now'),
                    //     ),
                    //   ],
                    // ),
                  ],
                ),
              ),
            ),

          ],
        ),
      ),
    );
  }
}


