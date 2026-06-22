/// ------------------------------------------------------------------
/// File: app_constants.dart
/// Role: Global Constants & Theming
/// 
/// Description:
/// Stores immutable configuration variables, API keys, color palettes, and global typography styles to ensure design consistency.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:flutter/material.dart';

class AppColors {
  static const primary = Color(0xFF1565C0);
  static const primaryLight = Color(0xFF1E88E5);
  static const primaryDark = Color(0xFF0D47A1);
  static const accent = Color(0xFF42A5F5);
  static const background = Color(0xFFF5F7FA);
  static const surface = Colors.white;
  static const error = Color(0xFFD32F2F);

  // Status colors
  static const locked = Color(0xFF9E9E9E);
  static const pendingSubmission = Color(0xFFFF9800);
  static const submitted = Color(0xFF1565C0);
  static const changesRequested = Color(0xFFD32F2F);
  static const approved = Color(0xFF2E7D32);

  static const textPrimary = Color(0xFF212121);
  static const textSecondary = Color(0xFF757575);
  static const divider = Color(0xFFE0E0E0);
  static const cardShadow = Color(0x1A000000);
}

class AppStrings {
  static const appName = 'FYP Management System';
  static const login = 'Login';
  static const email = 'Email';
  static const password = 'Password';
  static const logout = 'Logout';

  // Roles
  static const student = 'student';
  static const supervisor = 'supervisor';
  static const admin = 'admin';

  // Phase titles
  static const List<String> phaseTitles = [
    'Project Proposal',
    'Literature Review',
    'System Design',
    'Development & Implementation',
    'Final Submission & Presentation',
  ];

  // Phase statuses
  static const locked = 'locked';
  static const pendingSubmission = 'pending_submission';
  static const submitted = 'submitted';
  static const changesRequested = 'changes_requested';
  static const approved = 'approved';
}

class AppDimensions {
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double borderRadius = 12.0;
  static const double cardElevation = 2.0;
}

class CloudinaryConfig {
  static const cloudName = 'dlvhosdnx';
  static const uploadPreset = 'ml_default';
}
