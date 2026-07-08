/// ------------------------------------------------------------------
/// File: login_screen.dart
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
import 'dart:math' as math;
import '../../providers/providers.dart';
import '../../constants/app_constants.dart';

class _ThemeColors {
  static const primary = Color(0xFF1E2F4F);
  static const backgroundStart = Color(0xFF090E17);
  static const backgroundEnd = Color(0xFF05080F);
  static const accent = Color(0xFF14B8A6);
  static const accentGlow = Color(0xFF2563EB);
  static const surface = Color(0xFF111827);
  static const border = Color(0xFF1F2937);
  static const textWhite = Colors.white;
  static const textGrey = Color(0xFF9CA3AF);
  static const btnStart = Color(0xFF2563EB);
  static const btnEnd = Color(0xFF1D4ED8);
}

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> with TickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _selectedRole;

  late AnimationController _entryController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    _entryController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    );
    _fadeAnim = Tween<double>(begin: 0, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0, 0.8, curve: Curves.easeOut)),
    );
    _slideAnim = Tween<Offset>(begin: const Offset(0, 0.05), end: Offset.zero).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0, 0.8, curve: Curves.easeOutCubic)),
    );
    _scaleAnim = Tween<double>(begin: 0.8, end: 1).animate(
      CurvedAnimation(parent: _entryController, curve: const Interval(0, 0.8, curve: Curves.easeOutBack)),
    );
    _entryController.forward();
  }

  @override
  void dispose() {
    _entryController.dispose();
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  Future<void> _login() async {
    if (_selectedRole == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Please select your role before signing in'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }
    if (!_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final ok = await auth.signIn(_emailCtrl.text.trim(), _passCtrl.text.trim());
    if (!mounted) return;
    if (ok && auth.currentUser != null) {
      final role = auth.currentUser!.role;
      switch (role) {
        case 'student':
          Navigator.pushReplacementNamed(context, '/student');
          break;
        case 'supervisor':
          Navigator.pushReplacementNamed(context, '/supervisor');
          break;
        case 'admin':
          Navigator.pushReplacementNamed(context, '/admin');
          break;
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(auth.error ?? 'Login failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    return Scaffold(
      backgroundColor: _ThemeColors.backgroundStart,
      body: Stack(
        children: [
          // Background Gradient
          Container(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_ThemeColors.backgroundStart, _ThemeColors.backgroundEnd],
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
              ),
            ),
          ),
          
          // Animated Background (Particles & Waves)
          const _AnimatedBackground(),

          // Faded University Illustration at bottom
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.12,
              child: CustomPaint(
                size: Size(MediaQuery.of(context).size.width, 220),
                painter: _UniversityPainter(),
              ),
            ),
          ),

          // Main Content
          SafeArea(
            child: FadeTransition(
              opacity: _fadeAnim,
              child: SlideTransition(
                position: _slideAnim,
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const SizedBox(height: 24),
                        // Logo with soft blue glow
                        ScaleTransition(
                          scale: _scaleAnim,
                          child: Center(
                            child: Container(
                              width: 110,
                              height: 110,
                              decoration: BoxDecoration(
                                color: Colors.white,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: _ThemeColors.accentGlow.withValues(alpha: 0.4),
                                    blurRadius: 40,
                                    spreadRadius: 8,
                                  ),
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.2),
                                    blurRadius: 10,
                                    spreadRadius: 2,
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.school,
                                  size: 54,
                                  color: _ThemeColors.primary,
                                ),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        // Title
                        RichText(
                          textAlign: TextAlign.center,
                          text: const TextSpan(
                            style: TextStyle(
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 0.5,
                            ),
                            children: [
                              TextSpan(
                                text: 'FYP ',
                                style: TextStyle(color: _ThemeColors.accentGlow),
                              ),
                              TextSpan(
                                text: 'Management System',
                                style: TextStyle(color: _ThemeColors.textWhite),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Subtle Divider
                        Center(
                          child: Container(
                            width: 32,
                            height: 3,
                            decoration: BoxDecoration(
                              color: _ThemeColors.accentGlow,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                        ),
                        const SizedBox(height: 32),
                        const Center(
                          child: Text(
                            'Select Your Role',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: _ThemeColors.textWhite,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        const Center(
                          child: Text(
                            'Please select your role before logging in',
                            style: TextStyle(
                              fontSize: 14,
                              color: _ThemeColors.textGrey,
                            ),
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Role Cards
                        Row(
                          children: [
                            _RoleChip(
                              label: 'Student',
                              icon: Icons.person,
                              isSelected: _selectedRole == 'student',
                              onTap: () => setState(() => _selectedRole = 'student'),
                            ),
                            const SizedBox(width: 12),
                            _RoleChip(
                              label: 'Supervisor',
                              icon: Icons.people,
                              isSelected: _selectedRole == 'supervisor',
                              onTap: () => setState(() => _selectedRole = 'supervisor'),
                            ),
                            const SizedBox(width: 12),
                            _RoleChip(
                              label: 'Admin',
                              icon: Icons.admin_panel_settings,
                              isSelected: _selectedRole == 'admin',
                              onTap: () => setState(() => _selectedRole = 'admin'),
                            ),
                          ],
                        ),
                        const SizedBox(height: 32),
                        // Email field
                        SizedBox(
                          height: 76,
                          child: TextFormField(
                            controller: _emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: _ThemeColors.textWhite),
                            decoration: InputDecoration(
                              labelText: 'Email',
                              labelStyle: const TextStyle(color: _ThemeColors.textGrey),
                              prefixIcon: const Icon(Icons.email_outlined, color: _ThemeColors.textGrey),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _ThemeColors.border, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _ThemeColors.border, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _ThemeColors.accentGlow, width: 1.5),
                              ),
                              filled: true,
                              fillColor: _ThemeColors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Email is required';
                              if (!v.contains('@')) return 'Enter valid email';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 12),
                        // Password field
                        SizedBox(
                          height: 76,
                          child: TextFormField(
                            controller: _passCtrl,
                            obscureText: _obscurePass,
                            style: const TextStyle(color: _ThemeColors.textWhite),
                            decoration: InputDecoration(
                              labelText: 'Password',
                              labelStyle: const TextStyle(color: _ThemeColors.textGrey),
                              prefixIcon: const Icon(Icons.lock_outlined, color: _ThemeColors.textGrey),
                              suffixIcon: IconButton(
                                icon: Icon(
                                  _obscurePass ? Icons.visibility_off : Icons.visibility,
                                  color: _ThemeColors.textGrey,
                                ),
                                onPressed: () => setState(() => _obscurePass = !_obscurePass),
                              ),
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _ThemeColors.border, width: 1),
                              ),
                              enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _ThemeColors.border, width: 1),
                              ),
                              focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(16),
                                borderSide: const BorderSide(color: _ThemeColors.accentGlow, width: 1.5),
                              ),
                              filled: true,
                              fillColor: _ThemeColors.surface,
                              contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
                            ),
                            validator: (v) {
                              if (v == null || v.isEmpty) return 'Password is required';
                              if (v.length < 6) return 'Min 6 characters';
                              return null;
                            },
                          ),
                        ),
                        const SizedBox(height: 24),
                        // Login button
                        _AnimatedLoginButton(
                          onPressed: auth.loading ? null : _login,
                          isLoading: auth.loading,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _AnimatedLoginButton extends StatefulWidget {
  final VoidCallback? onPressed;
  final bool isLoading;

  const _AnimatedLoginButton({required this.onPressed, required this.isLoading});

  @override
  State<_AnimatedLoginButton> createState() => _AnimatedLoginButtonState();
}

class _AnimatedLoginButtonState extends State<_AnimatedLoginButton> {
  bool _isPressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) {
        if (widget.onPressed != null) setState(() => _isPressed = true);
      },
      onTapUp: (_) {
        if (widget.onPressed != null) {
          setState(() => _isPressed = false);
          widget.onPressed!();
        }
      },
      onTapCancel: () {
        if (widget.onPressed != null) setState(() => _isPressed = false);
      },
      child: AnimatedScale(
        scale: _isPressed ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 100),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: 56,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            gradient: LinearGradient(
              colors: widget.onPressed == null 
                  ? [_ThemeColors.surface, _ThemeColors.border]
                  : [_ThemeColors.btnStart, _ThemeColors.btnEnd],
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
            ),
            boxShadow: widget.onPressed == null ? [] : [
              BoxShadow(
                color: _ThemeColors.accentGlow.withValues(alpha: _isPressed ? 0.2 : 0.4),
                blurRadius: _isPressed ? 8 : 16,
                offset: Offset(0, _isPressed ? 2 : 4),
              ),
            ],
          ),
          child: Center(
            child: widget.isLoading
                ? const SizedBox(
                    height: 24,
                    width: 24,
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2.5),
                  )
                : const Text(
                    'Login',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
          ),
        ),
      ),
    );
  }
}

class _RoleChip extends StatelessWidget {
  final String label;
  final IconData icon;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 20),
          decoration: BoxDecoration(
            color: _ThemeColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? _ThemeColors.accentGlow : _ThemeColors.border,
              width: isSelected ? 1.5 : 1,
            ),
            boxShadow: isSelected ? [
              BoxShadow(
                color: _ThemeColors.accentGlow.withValues(alpha: 0.15),
                blurRadius: 16,
                spreadRadius: 2,
              )
            ] : [],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              AnimatedSwitcher(
                duration: const Duration(milliseconds: 300),
                child: Icon(
                  icon,
                  key: ValueKey<bool>(isSelected),
                  color: isSelected ? _ThemeColors.accentGlow : _ThemeColors.textGrey,
                  size: 32,
                ),
              ),
              const SizedBox(height: 12),
              AnimatedDefaultTextStyle(
                duration: const Duration(milliseconds: 300),
                style: TextStyle(
                  fontSize: 14,
                  color: isSelected ? _ThemeColors.accentGlow : _ThemeColors.textGrey,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground();
  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground> with SingleTickerProviderStateMixin {
  late AnimationController _bgController;
  final List<_Particle> _particles = List.generate(40, (_) => _Particle());

  @override
  void initState() {
    super.initState();
    _bgController = AnimationController(vsync: this, duration: const Duration(seconds: 15))..repeat();
  }

  @override
  void dispose() {
    _bgController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _bgController,
      builder: (context, child) {
        for (var p in _particles) {
          p.update();
        }
        return CustomPaint(
          size: Size.infinite,
          painter: _BgPainter(_particles, _bgController.value),
        );
      },
    );
  }
}

class _Particle {
  double x = math.Random().nextDouble();
  double y = math.Random().nextDouble();
  double speed = math.Random().nextDouble() * 0.001 + 0.0002;
  double radius = math.Random().nextDouble() * 2 + 0.5;
  double alpha = math.Random().nextDouble() * 0.4 + 0.1;

  void update() {
    y -= speed;
    if (y < 0) {
      y = 1.0;
      x = math.Random().nextDouble();
    }
  }
}

class _BgPainter extends CustomPainter {
  final List<_Particle> particles;
  final double animationValue;

  _BgPainter(this.particles, this.animationValue);

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
      
    // Draw waves
    final wavePaint = Paint()
      ..color = _ThemeColors.accentGlow.withValues(alpha: 0.03)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;

    for (int i = 0; i < 3; i++) {
      final path = Path();
      path.moveTo(0, size.height * (0.2 + i * 0.25));
      for (double x = 0; x <= size.width; x += 20) {
        final y = math.sin((x / size.width * math.pi * 1.5) + (animationValue * math.pi * 2) + (i * 2)) * 40;
        path.lineTo(x, size.height * (0.2 + i * 0.25) + y);
      }
      canvas.drawPath(path, wavePaint);
    }

    // Draw particles
    for (var p in particles) {
      paint.color = _ThemeColors.accentGlow.withValues(alpha: p.alpha * 0.8);
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.radius, paint);
      
      // Inner bright core
      paint.color = Colors.white.withValues(alpha: p.alpha);
      canvas.drawCircle(Offset(p.x * size.width, p.y * size.height), p.radius * 0.5, paint);
    }
  }

  @override
  bool shouldRepaint(covariant _BgPainter oldDelegate) => true;
}

class _UniversityPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    // Background glow behind the university
    final glowPaint = Paint()
      ..color = _ThemeColors.accentGlow.withValues(alpha: 0.6)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 50);
      
    canvas.drawCircle(Offset(size.width * 0.5, size.height * 0.8), size.width * 0.4, glowPaint);

    final paint = Paint()
      ..color = const Color(0xFF070B14)
      ..style = PaintingStyle.fill;
      
    // Draw some stylized university silhouettes and trees
    final path = Path();
    path.moveTo(0, size.height * 0.8);
    path.quadraticBezierTo(size.width * 0.5, size.height * 0.6, size.width, size.height * 0.8);
    path.lineTo(size.width, size.height);
    path.lineTo(0, size.height);
    path.close();
    canvas.drawPath(path, paint);

    final centerBuilding = Rect.fromLTWH(size.width * 0.35, size.height * 0.4, size.width * 0.3, size.height * 0.4);
    canvas.drawRect(centerBuilding, paint);
    
    final pillarPaint = Paint()..color = _ThemeColors.backgroundStart.withValues(alpha: 0.5);
    for (int i = 0; i < 4; i++) {
      canvas.drawRect(
        Rect.fromLTWH(size.width * 0.38 + (i * size.width * 0.07), size.height * 0.5, size.width * 0.03, size.height * 0.3),
        pillarPaint
      );
    }
    
    final roofPath = Path();
    roofPath.moveTo(size.width * 0.32, size.height * 0.4);
    roofPath.lineTo(size.width * 0.5, size.height * 0.25);
    roofPath.lineTo(size.width * 0.68, size.height * 0.4);
    roofPath.close();
    canvas.drawPath(roofPath, paint);

    canvas.drawRect(Rect.fromLTWH(size.width * 0.2, size.height * 0.55, size.width * 0.15, size.height * 0.25), paint);
    canvas.drawRect(Rect.fromLTWH(size.width * 0.65, size.height * 0.55, size.width * 0.15, size.height * 0.25), paint);
    
    canvas.drawCircle(Offset(size.width * 0.1, size.height * 0.6), size.width * 0.06, paint);
    canvas.drawCircle(Offset(size.width * 0.15, size.height * 0.5), size.width * 0.05, paint);
    canvas.drawCircle(Offset(size.width * 0.9, size.height * 0.6), size.width * 0.06, paint);
    canvas.drawCircle(Offset(size.width * 0.85, size.height * 0.5), size.width * 0.05, paint);
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
