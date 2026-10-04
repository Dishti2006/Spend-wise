import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'dashboard.dart';
import 'main.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});
  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {

  late AnimationController _controller;
  late Animation<double> _fadeAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );

    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeIn),
    );

    _scaleAnim = Tween<double>(begin: 0.7, end: 1).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );

    _controller.forward();

    // ✅ After 3 seconds check if user is logged in
    Future.delayed(const Duration(seconds: 3), () {
      if (!mounted) return;
      final user = FirebaseAuth.instance.currentUser;
      Navigator.pushReplacement(
        context,
        MaterialPageRoute(
          builder: (_) => user != null
              ? const Dashboard()   // ✅ already signed in → Dashboard
              : const FrontWidget(), // not signed in → login page
        ),
      );
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFF0A0E1A),
      body: Stack(
        children: [

          // Background gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [
                  Color(0xFF0A0E1A),
                  Color(0xFF0D1F3C),
                  Color(0xFF0A0E1A),
                ],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
            ),
          ),

          // Top glow
          Align(
            alignment: const Alignment(-1, -1),
            child: Opacity(
              opacity: 0.5,
              child: Container(
                width: 300, height: 300,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0x441A6BFF), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Bottom glow
          Align(
            alignment: const Alignment(1, 1),
            child: Opacity(
              opacity: 0.4,
              child: Container(
                width: 250, height: 250,
                decoration: const BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: [Color(0x3300C896), Colors.transparent],
                  ),
                ),
              ),
            ),
          ),

          // Main content
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [

                    // Logo box
                    Container(
                      width: 110,
                      height: 110,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(30),
                        color: const Color(0xFF0F1628),
                        border: Border.all(
                          color: const Color(0xFF2E7FFF),
                          width: 3,
                        ),
                      ),
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(27),
                        child: CustomPaint(
                          painter: _LogoPainter(),
                        ),
                      ),
                    ),

                    const SizedBox(height: 28),

                    // SpendSense name
                    RichText(
                      text: const TextSpan(
                        children: [
                          TextSpan(
                            text: "Spend",
                            style: TextStyle(
                              color: Color(0xFF60AAFF),
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                          TextSpan(
                            text: "Sense",
                            style: TextStyle(
                              color: Color(0xFF00E8A8),
                              fontSize: 36,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 10),

                    // Tagline
                    Text(
                      "Smart Money. Smarter Decisions.",
                      style: GoogleFonts.inter(
                        color: Colors.white.withOpacity(0.5),
                        fontSize: 14,
                        letterSpacing: 0.5,
                      ),
                    ),

                    const SizedBox(height: 60),

                    // Loading dots
                    _LoadingDots(),
                  ],
                ),
              ),
            ),
          ),

          // Version
          Positioned(
            bottom: 30,
            left: 0, right: 0,
            child: Text(
              "v1.0.0",
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white.withOpacity(0.2),
                fontSize: 12,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// Logo painter
class _LogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    final bgPaint = Paint()..color = const Color(0xFF0F1628);
    canvas.drawRect(Rect.fromLTWH(0, 0, w, h), bgPaint);

    final walletPaint = Paint()
      ..color = const Color(0xFF2E7FFF)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w*0.12, h*0.25, w*0.76, h*0.55),
        const Radius.circular(8),
      ),
      walletPaint,
    );

    final flapPaint = Paint()..color = const Color(0xFF2E7FFF);
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        Rect.fromLTWH(w*0.12, h*0.25, w*0.76, h*0.16),
        const Radius.circular(7),
      ),
      flapPaint,
    );

    final coinBorderPaint = Paint()
      ..color = const Color(0xFF00E8A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(Offset(w*0.72, h*0.35), w*0.13, coinBorderPaint);

    final textPainter = TextPainter(
      text: const TextSpan(
        text: '₹',
        style: TextStyle(
          color: Color(0xFF00E8A8),
          fontSize: 14,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(w*0.72 - textPainter.width/2, h*0.35 - textPainter.height/2),
    );

    final linePaint = Paint()
      ..color = const Color(0xFF00E8A8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final path = Path();
    path.moveTo(w*0.15, h*0.72);
    path.lineTo(w*0.30, h*0.58);
    path.lineTo(w*0.42, h*0.65);
    path.lineTo(w*0.55, h*0.45);
    canvas.drawPath(path, linePaint);

    final dotPaint = Paint()..color = const Color(0xFF00E8A8);
    canvas.drawCircle(Offset(w*0.55, h*0.45), 4, dotPaint);
    final dotInnerPaint = Paint()..color = const Color(0xFF0F1628);
    canvas.drawCircle(Offset(w*0.55, h*0.45), 2, dotInnerPaint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

// Animated loading dots
class _LoadingDots extends StatefulWidget {
  @override
  State<_LoadingDots> createState() => _LoadingDotsState();
}

class _LoadingDotsState extends State<_LoadingDots>
    with SingleTickerProviderStateMixin {
  late AnimationController _ctrl;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat();
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _ctrl,
      builder: (_, __) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(3, (i) {
            double opacity = ((_ctrl.value * 3) - i).clamp(0.0, 1.0);
            if (opacity > 1) opacity = 2 - opacity;
            return Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              width: 8, height: 8,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: const Color(0xFF1A6BFF).withOpacity(0.3 + opacity * 0.7),
              ),
            );
          }),
        );
      },
    );
  }
}