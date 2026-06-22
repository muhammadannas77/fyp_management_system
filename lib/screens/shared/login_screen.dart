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
import '../../providers/providers.dart';
import '../../constants/app_constants.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _obscurePass = true;
  String? _selectedRole;

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  /// -----------------------------------------
  /// Method: _login
  /// Purpose: Executes logic for _login and handles state or UI updates.
  /// -----------------------------------------
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
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 32),
                // Logo
                Center(
                  child: Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: AppColors.primary.withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Icon(Icons.school, size: 48, color: Colors.white),
                  ),
                ),
                const SizedBox(height: 24),
                const Center(
                  child: Text(
                    'FYP Management System',
                    style: TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                const Center(
                  child: Text(
                    'Select Your Role',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 6),
                const Center(
                  child: Text(
                    'Please select your role before signing in',
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                Row(
                  children: [
                    _RoleChip(
                      label: 'Student',
                      icon: Icons.person,
                      color: AppColors.primary,
                      isSelected: _selectedRole == 'student',
                      onTap: () => setState(() => _selectedRole = 'student'),
                    ),
                    const SizedBox(width: 8),
                    _RoleChip(
                      label: 'Supervisor',
                      icon: Icons.supervisor_account,
                      color: AppColors.approved,
                      isSelected: _selectedRole == 'supervisor',
                      onTap: () => setState(() => _selectedRole = 'supervisor'),
                    ),
                    const SizedBox(width: 8),
                    _RoleChip(
                      label: 'Admin',
                      icon: Icons.admin_panel_settings,
                      color: AppColors.changesRequested,
                      isSelected: _selectedRole == 'admin',
                      onTap: () => setState(() => _selectedRole = 'admin'),
                    ),
                  ],
                ),
                const SizedBox(height: 32),
                // Email field
                TextFormField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email_outlined),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Email is required';
                    if (!v.contains('@')) return 'Enter valid email';
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                // Password field
                TextFormField(
                  controller: _passCtrl,
                  obscureText: _obscurePass,
                  decoration: InputDecoration(
                    labelText: 'Password',
                    prefixIcon: const Icon(Icons.lock_outlined),
                    suffixIcon: IconButton(
                      icon: Icon(
                        _obscurePass ? Icons.visibility_off : Icons.visibility,
                      ),
                      onPressed: () =>
                          setState(() => _obscurePass = !_obscurePass),
                    ),
                  ),
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Password is required';
                    if (v.length < 6) return 'Min 6 characters';
                    return null;
                  },
                ),
                const SizedBox(height: 28),
                // Login button
                ElevatedButton(
                  onPressed: auth.loading ? null : _login,
                  child: auth.loading
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2),
                        )
                      : const Text('Login'),
                ),
              ],
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
  final Color color;
  final bool isSelected;
  final VoidCallback onTap;

  const _RoleChip({
    required this.label,
    required this.icon,
    required this.color,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: GestureDetector(
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: isSelected ? color.withValues(alpha: 0.12) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isSelected ? color : AppColors.divider,
              width: isSelected ? 2 : 1,
            ),
          ),
          child: Column(
            children: [
              Icon(
                icon, 
                color: isSelected ? color : AppColors.textSecondary, 
                size: 24
              ),
              const SizedBox(height: 6),
              Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  color: isSelected ? color : AppColors.textSecondary,
                  fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
