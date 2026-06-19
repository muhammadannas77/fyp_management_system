import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FCMService {
  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const _channelId = 'fyp_channel';
  static const _channelName = 'FYP Notifications';

  Future<void> initialize() async {
    // Request permission
    await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // Local notifications — only on non-web
    if (!kIsWeb) {
      const androidSettings =
          AndroidInitializationSettings('@mipmap/ic_launcher');
      const iosSettings = DarwinInitializationSettings(
        requestAlertPermission: true,
        requestBadgePermission: true,
        requestSoundPermission: true,
      );
      const initSettings =
          InitializationSettings(android: androidSettings, iOS: iosSettings);
      await _localNotifications.initialize(initSettings);

      // Create high-importance channel (Android 8+)
      const androidChannel = AndroidNotificationChannel(
        _channelId,
        _channelName,
        description: 'FYP Management System phase & review notifications',
        importance: Importance.high,
        playSound: true,
      );
      await _localNotifications
          .resolvePlatformSpecificImplementation<
              AndroidFlutterLocalNotificationsPlugin>()
          ?.createNotificationChannel(androidChannel);
    }

    // Foreground message handler
    FirebaseMessaging.onMessage.listen(_handleForeground);

    // When app opened from notification (background → foreground)
    FirebaseMessaging.onMessageOpenedApp.listen(_handleOpened);

    // Get FCM token (useful for debugging)
    final token = await _messaging.getToken();
    // ignore: avoid_print
    print('[FCM] Token: $token');
  }

  void _handleForeground(RemoteMessage message) {
    if (kIsWeb) return;
    final notification = message.notification;
    if (notification == null) return;

    _localNotifications.show(
      notification.hashCode,
      notification.title ?? 'FYP Update',
      notification.body ?? '',
      const NotificationDetails(
        android: AndroidNotificationDetails(
          _channelId,
          _channelName,
          importance: Importance.high,
          priority: Priority.high,
          icon: '@mipmap/ic_launcher',
        ),
        iOS: DarwinNotificationDetails(
          presentAlert: true,
          presentBadge: true,
          presentSound: true,
        ),
      ),
    );
  }

  void _handleOpened(RemoteMessage message) {
    // Could navigate to specific screen based on message.data
    // e.g. message.data['projectId'], message.data['phaseNo']
  }

  Future<String?> getToken() => _messaging.getToken();
}
