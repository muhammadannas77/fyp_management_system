/// ------------------------------------------------------------------
/// File: splash_screen.dart
/// Role: User Interface (View)
/// 
/// Description:
/// Renders the visual elements of the application. Listens to Providers for state changes to display data dynamically. Contains purely presentation logic without direct database manipulation.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../providers/providers.dart';
import '../../constants/app_constants.dart';

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
        vsync: this, duration: const Duration(milliseconds: 1000));
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.easeIn));
    _scaleAnim = Tween<double>(begin: 0.75, end: 1).animate(
        CurvedAnimation(parent: _controller, curve: Curves.elasticOut));
    _controller.forward();

    // Wait for auth to settle then navigate
    _waitAndNavigate();
  }

  /// -----------------------------------------
  /// Method: _waitAndNavigate
  /// Purpose: Executes logic for _waitAndNavigate and handles state or UI updates.
  /// -----------------------------------------
  Future<void> _waitAndNavigate() async {
    // Minimum splash time
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    final auth = context.read<AuthProvider>();

    // Poll until auth is no longer unknown (max 3 extra seconds)
    int waited = 0;
    while (auth.status == AuthStatus.unknown && waited < 6) {
      await Future.delayed(const Duration(milliseconds: 500));
      waited++;
      if (!mounted) return;
    }

    if (!mounted) return;
    _redirect(auth);
  }

  /// -----------------------------------------
  /// Method: _redirect
  /// Purpose: Executes logic for _redirect and handles state or UI updates.
  /// -----------------------------------------
  void _redirect(AuthProvider auth) {
    if (auth.status == AuthStatus.authenticated && auth.currentUser != null) {
      switch (auth.currentUser!.role) {
        case 'student':
          Navigator.pushReplacementNamed(context, '/student');
          break;
        case 'supervisor':
          Navigator.pushReplacementNamed(context, '/supervisor');
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
        default:
          Navigator.pushReplacementNamed(context, '/login');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: Stack(
        children: [
          // Bottom faded university illustration
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.1,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 200),
                painter: _UniversityPainter(),
              ),
            ),
          ),
          Center(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: ScaleTransition(
                scale: _scaleAnim,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // Centered circular logo with soft teal glow
                    Container(
                      width: 120,
                      height: 120,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: AppColors.accent.withValues(alpha: 0.3),
                            blurRadius: 30,
                            spreadRadius: 10,
                          ),
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.05),
                            blurRadius: 10,
                            spreadRadius: 1,
                          ),
                        ],
                      ),
                      child: const Center(
                        child: Icon(
                          Icons.school,
                          size: 64,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    // Title
                    const Text(
                      'FYP',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 48,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 1.5,
                      ),
                    ),
                    const Text(
                      'MANAGEMENT SYSTEM',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        letterSpacing: 1.2,
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Small teal divider
                    Container(
                      width: 40,
                      height: 3,
                      decoration: BoxDecoration(
                        color: AppColors.accent,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                    const SizedBox(height: 16),
                    // Subtitle
                    const Text(
                      'Streamline. Track. Succeed.',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 64),
                    // Elegant loading indicator
                    const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: AppColors.accent,
                        strokeWidth: 2.5,
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Loading your workspace...',
                      style: TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _UniversityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = AppColors.primary
      ..style = PaintingStyle.fill;
      
    // Draw some stylized university silhouettes and trees
    // Ground curve
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width, size.height * 0.8);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    // Main Building
    final centerBuilding = Rect.fromLTWH(size.width * 0.35, size.height * 0.4, size.width * 0.3, size.height * 0.4);
    canvas.drawRect(centerBuilding, paint);
    
    // Pillars
    final pillarPaint = Paint()..color = AppColors.background.withValues(alpha: 0.5);
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.38 + (i * size.width * 0.07), size.height * 0.5, size.width * 0.03, size.height * 0.3),
        pillarPaint
      );
    }
    
    // Roof triangle
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.32, size.height * 0.4);
    roofPath.lineTo(size.width * 0.5, size.height * 0.25);
    roofPath.lineTo(size.width * 0.68, size.height * 0.4);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    // Side buildings
    canvas.drawRect(Rect.fromLTWH(size.width * 0.2, size.height * 0.55, size.width * 0.15, size.height * 0.25), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.65, size.height * 0.55, size.width * 0.15, size.height * 0.25), paint);
    
    // Trees
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.6), size.width * 0.06, paint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.5), size.width * 0.05, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.6), size.width * 0.06, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.5), size.width * 0.05, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
