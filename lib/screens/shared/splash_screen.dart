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
      backgroundColor: AppColors.primary,
      body: Center(
        child: FadeTransition(
          opacity: _fadeAnim,
          child: ScaleTransition(
            scale: _scaleAnim,
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.school, size: 56, color: Colors.white),
                ),
                const SizedBox(height: 24),
                const Text(
                  'FYP Management\nSystem',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    height: 1.3,
                  ),
                ),
                const SizedBox(height: 10),
                Text(
                  'Phase-based Academic Workflow',
                  style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8), fontSize: 14),
                ),
                const SizedBox(height: 52),
                const SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(
                      color: Colors.white, strokeWidth: 2.5),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
