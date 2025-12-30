import 'package:flutter/material.dart';
import 'dart:math';
class SignatureBackground extends StatelessWidget {
  final Widget child;
  final double opacity;
  final List<Color> gradientColors;
  final bool useDarkWaves;

  const SignatureBackground({
    Key? key,
    required this.child,
    this.opacity = 0.2,
    this.gradientColors = const [Colors.deepPurple, Colors.deepPurpleAccent],
    this.useDarkWaves = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return CustomPaint(
      painter: _RibbonBackgroundPainter(
        opacity: opacity,
        gradientColors: gradientColors,
        useDarkWaves: useDarkWaves,
      ),
      child: child,
    );
  }
}

class _RibbonBackgroundPainter extends CustomPainter {
  final double opacity;
  final List<Color> gradientColors;
  final bool useDarkWaves;

  _RibbonBackgroundPainter({
    required this.opacity,
    required this.gradientColors,
    required this.useDarkWaves,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = LinearGradient(
        colors: gradientColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height))
      ..style = PaintingStyle.fill
      ..isAntiAlias = true;

    final topPath = Path();
    final bottomPath = Path();
    final waveHeight = 40.0; // Height of the wave

    // 🎀 Top Ribbon Wave (covers top 25% of the screen height)
    topPath.moveTo(0, 0);
    topPath.quadraticBezierTo(size.width * 0.25, -waveHeight, size.width * 0.5, 0);
    topPath.quadraticBezierTo(size.width * 0.75, waveHeight, size.width, 0);
    topPath.lineTo(size.width, size.height * 0.25);  // Limit to top 25%
    topPath.close();

    // 🎀 Bottom Ribbon Wave (covers bottom 25% of the screen height)
    bottomPath.moveTo(0, size.height);
    bottomPath.quadraticBezierTo(size.width * 0.25, size.height + waveHeight, size.width * 0.5, size.height);
    bottomPath.quadraticBezierTo(size.width * 0.75, size.height - waveHeight, size.width, size.height);
    bottomPath.lineTo(size.width, size.height * 0.75); // Limit to bottom 25%
    bottomPath.close();

    paint.color = paint.color.withOpacity(opacity);
    canvas.drawPath(topPath, paint);
    canvas.drawPath(bottomPath, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
