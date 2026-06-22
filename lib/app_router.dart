/// ------------------------------------------------------------------
/// File: app_router.dart
/// Role: Core Architecture File
/// 
/// Description:
/// Serves as an integral part of the FYP Management System architecture.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:flutter/material.dart';
import '../screens/shared/splash_screen.dart';
import '../screens/shared/login_screen.dart';
import '../screens/shared/notifications_screen.dart';
import '../screens/student/student_dashboard.dart';
import '../screens/supervisor/supervisor_dashboard.dart';
import '../screens/admin/admin_dashboard.dart';

class AppRouter {
  /// -----------------------------------------
  /// Method: generateRoute
  /// Purpose: Executes logic for generateRoute and handles state or UI updates.
  /// -----------------------------------------
  static Route<dynamic> generateRoute(RouteSettings settings) {
    switch (settings.name) {
      case '/':
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case '/login':
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case '/student':
        return MaterialPageRoute(builder: (_) => const StudentDashboard());
      case '/supervisor':
        return MaterialPageRoute(builder: (_) => const SupervisorDashboard());
      case '/admin':
        return MaterialPageRoute(builder: (_) => const AdminDashboard());
      case '/notifications':
        return MaterialPageRoute(builder: (_) => const NotificationsScreen());
      default:
        return MaterialPageRoute(
          builder: (_) => Scaffold(
            body: Center(
              child: Text('Route ${settings.name} not found'),
            ),
          ),
        );
    }
  }
}
