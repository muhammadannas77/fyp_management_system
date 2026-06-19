import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'constants/app_theme.dart';
import 'providers/providers.dart';
import 'app_router.dart';

class FypApp extends StatelessWidget {
  const FypApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AuthProvider()),
        ChangeNotifierProvider(create: (_) => ProjectProvider()),
        ChangeNotifierProvider(create: (_) => AdminProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: MaterialApp(
        title: 'FYP Management System',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.lightTheme,
        initialRoute: '/',
        onGenerateRoute: AppRouter.generateRoute,
      ),
    );
  }
}
