import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:online_classes/Screens/Auth/signinScreen.dart';
import 'package:online_classes/Screens/Teachers/screens/TeacherDashboardScreen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'OtpScreen.dart';
import 'TeacherSiginin.dart';

class AskType extends StatefulWidget {
  const AskType({super.key});

  @override
  State<AskType> createState() => _AskTypeState();
}

class _AskTypeState extends State<AskType> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;

  late AnimationController _centerZoomController;
  bool isAnimating = false;
  String? selectedRole;
  GlobalKey _cardKey = GlobalKey();

  Offset cardOffset = Offset.zero;
  Size cardSize = Size.zero;
  clear()async{
    SharedPreferences preferences =await SharedPreferences.getInstance();
    await preferences.setString('type', '');
  }

  @override
  void initState() {
    super.initState();
    clear();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.2).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _centerZoomController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _centerZoomController.dispose();
    super.dispose();
  }

  void _onCardTap(String role, GlobalKey key,bool teacher) async {
    final RenderBox renderBox = key.currentContext!.findRenderObject() as RenderBox;
    final position = renderBox.localToGlobal(Offset.zero);
    final size = renderBox.size;

    setState(() {
      isAnimating = true;
      selectedRole = role;
      cardOffset = position;
      cardSize = size;
    });

    await _centerZoomController.forward();

    if (context.mounted) {
      if(teacher==true){

        Navigator.push(context, PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, __, ___) => TeacherSigninScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ));
        
      }else{

        Navigator.push(context, PageRouteBuilder(
          transitionDuration: const Duration(milliseconds: 900),
          pageBuilder: (_, __, ___) => const SigninScreen(),
          transitionsBuilder: (_, animation, __, child) {
            return FadeTransition(opacity: animation, child: child);
          },
        ));
        
      }

      _centerZoomController.reset();
      setState(() {
        isAnimating = false;
        selectedRole = null;
      });
    }
  }

  Widget _buildAnimatedCard() {
    if (!isAnimating || selectedRole == null) return const SizedBox.shrink();

    final double targetTop = MediaQuery.of(context).size.height / 2 - cardSize.height / 2;
    final double targetLeft = MediaQuery.of(context).size.width / 2 - cardSize.width / 2;

    return AnimatedBuilder(
      animation: _centerZoomController,
      builder: (context, child) {
        final double t = _centerZoomController.value;
        final double top = lerpDouble(cardOffset.dy, targetTop, t)!;
        final double left = lerpDouble(cardOffset.dx, targetLeft, t)!;
        final double scale = lerpDouble(1.0, 2.0, t)!;

        return Positioned(
          top: top,
          left: left,
          child: Transform.scale(
            scale: scale,
            child: _buildCard(
              icon: selectedRole == 'student' ? Icons.school : Icons.tag_faces,
              title: selectedRole == 'student' ? 'Student' : 'Teacher',
              subtitle: selectedRole == 'student' ? 'Learning every day' : 'Guiding the way',
              color: selectedRole == 'student' ? Colors.green : Colors.deepOrange,
              role: selectedRole!,
              key: GlobalKey(), // Dummy key for animation
              isStatic: true, teacher: selectedRole == 'student' ? false:true,
            ),
          ),
        );
      },
    );
  }

  Widget _buildCard({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required String role,
    required GlobalKey key,
    bool isStatic = false,
    required bool teacher
    
  }) {
    Widget cardContent = ScaleTransition(
      scale: isStatic ? AlwaysStoppedAnimation(1.0) : _pulseAnimation,
      child: Card(
        key: key,
        elevation: 10,
        color: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 50, color: color),
              const SizedBox(height: 10),
              Text(title, style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold)),
              Text(subtitle, style: const TextStyle(color: Colors.grey)),
            ],
          ),
        ),
      ),
    );

    if (isStatic) return cardContent;

    return InkWell(
      onTap: () => _onCardTap(role, key, teacher),
      child: cardContent,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(title: const Text('Who Are You'), backgroundColor: Colors.white),
      body: Stack(
        children: [
          AbsorbPointer(
            absorbing: isAnimating,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                children: [
                  Lottie.asset(
                    'assets/images/welcome.json',
                    width: double.maxFinite,
                    height: MediaQuery.of(context).size.height * 0.4,
                    fit: BoxFit.contain,
                  ),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
                        child: _buildCard(
                          icon: Icons.school,
                          title: 'Student',
                          subtitle: 'Learning every day',
                          color: Colors.green,
                          role: 'student',
                          key: _cardKey, teacher: false,
                        ),
                      ),
                      const SizedBox(width: 16),
                      Expanded(
                        child: _buildCard(
                          icon: Icons.tag_faces,
                          title: 'Teacher',
                          subtitle: 'Guiding the way',
                          color: Colors.deepOrange,
                          role: 'teacher',
                          key: GlobalKey(), teacher: true,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),

          // Blur background
          if (isAnimating)
            BackdropFilter(
              filter: ImageFilter.blur(sigmaX: 8.0, sigmaY: 8.0),
              child: Container(
                color: Colors.black.withOpacity(0.2),
              ),
            ),

          // Flying Card
          _buildAnimatedCard(),
        ],
      ),
    );
  }
}
