import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'app.dart';
import 'services/fcm_service.dart';
import 'firebase_options.dart';

/// FCM background handler — must be top-level function
@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  // Background message received — no UI work here
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Register background handler BEFORE anything else
  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  final fcm = FCMService();
  await fcm.initialize();

  runApp(const FypApp());
}
