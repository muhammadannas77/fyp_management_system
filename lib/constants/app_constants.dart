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
  static const primary = Color(0xFF1E2F4F);
  static const primaryLight = Color(0xFF334155);
  static const primaryDark = Color(0xFF0F172A);
  static const accent = Color(0xFF14B8A6);
  static const background = Color(0xFFF8FAFC);
  static const surface = Color(0xFFFFFFFF);
  static const error = Color(0xFFEF4444);

  // Status colors
  static const locked = Color(0xFF9CA3AF); // Grey
  static const pendingSubmission = Color(0xFFF59E0B); // Orange
  static const submitted = Color(0xFF3B82F6); // Blue
  static const changesRequested = Color(0xFFEF4444); // Red (Rejected)
  static const approved = Color(0xFF59D65F); // Success Green

  static const textPrimary = Color(0xFF1F2937);
  static const textSecondary = Color(0xFF6B7280);
  static const divider = Color(0xFFE5E7EB);
  static const cardShadow = Color(0x0A000000);
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
  static const double borderRadius = 16.0; // Updated to 16 for cards/buttons
  static const double cardElevation = 0.0; // Soft shadow in theme instead

  // New Spacing System
  static const double spacing4 = 4.0;
  static const double spacing8 = 8.0;
  static const double spacing12 = 12.0;
  static const double spacing16 = 16.0;
  static const double spacing20 = 20.0;
  static const double spacing24 = 24.0;
  static const double spacing32 = 32.0;
  static const double spacing40 = 40.0;
  static const double spacing48 = 48.0;
  static const double spacing64 = 64.0;
  
  static const double radiusCard = 16.0;
  static const double radiusButton = 16.0;
  static const double radiusInput = 16.0;
  static const double radiusDialog = 20.0;
  static const double radiusChip = 20.0;
}

class CloudinaryConfig {
  static const cloudName = 'dlvhosdnx';
  static const uploadPreset = 'ml_default';
}
