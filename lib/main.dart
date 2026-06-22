/// ------------------------------------------------------------------
/// File: main.dart
/// Role: Core Architecture File
/// 
/// Description:
/// Serves as an integral part of the FYP Management System architecture.
/// 
/// This file is part of the FYP Management System ecosystem.
/// It strictly adheres to the MVVM architectural pattern.
/// ------------------------------------------------------------------

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'services/fcm_service.dart';
import 'firebase_options.dart';

/// ------------------------------------------------------------------
/// FYP Management System - Main Entry Point
/// ------------------------------------------------------------------
/// This file serves as the root initializer of the application. 
/// Its primary responsibilities include:
/// 1. Initializing the Flutter binding.
/// 2. Establishing a connection to Firebase.
/// 3. Setting up background push notification handlers.
/// ------------------------------------------------------------------

/// FCM background handler — must be a top-level or static function.
/// This function listens for Firebase Cloud Messaging (FCM) push notifications 
/// when the app is completely closed or running in the background.
/// We initialize Firebase here again because the background isolate 
/// runs independently from the main app isolate.
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background message received. No UI rendering logic can happen here.
}

/// The main execution function of the application.
void main() async {
  // Ensures that widget bindings are fully initialized before any asynchronous calls.
  WidgetsFlutterBinding.ensureInitialized();

  // Initialize Firebase with platform-specific options (Android/iOS/Web).
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register the background handler BEFORE instantiating any other services
  // to guarantee that no push notifications are missed during startup.
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  // Initialize the local notification service to handle foreground alerts.
  final fcm = FCMService();
  await fcm.initialize();

  // Run the core app widget, which sets up the Providers and Theme.
  runApp(const FypApp());
}

