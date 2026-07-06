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
  static const primary = Color(0xFF6E40C9);
  static const primaryLight = Color(0xFF8957E5);
  static const primaryDark = Color(0xFF4B2B8C);
  static const accent = Color(0xFF58A6FF);
  static const background = Color(0xFF0D1117);
  static const surface = Color(0xFF161B22);
  static const error = Color(0xFFF85149);

  // Status colors
  static const locked = Color(0xFF484F58);
  static const pendingSubmission = Color(0xFFD29922);
  static const submitted = Color(0xFF58A6FF);
  static const changesRequested = Color(0xFFF85149);
  static const approved = Color(0xFF3FB950);

  static const textPrimary = Color(0xFFE6EDF3);
  static const textSecondary = Color(0xFF8B949E);
  static const divider = Color(0xFF30363D);
  static const cardShadow = Color(0xFF010409);
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
