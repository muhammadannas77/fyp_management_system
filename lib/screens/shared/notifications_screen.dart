/// ------------------------------------------------------------------
/// File: notifications_screen.dart
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
import '../../widgets/widgets.dart';

class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final auth = context.read<AuthProvider>();
    final notifProvider = context.watch<NotificationProvider>();
    final notifications = notifProvider.notifications;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        actions: [
          TextButton.icon(
            onPressed: () async {
              final hasUnread = notifications.any((n) => !n.isRead);
              if (!hasUnread) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('No unread notifications')),
                );
                return;
              }
              await notifProvider.markAllAsRead(auth.currentUser!.id);
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('All notifications marked as read')),
                );
              }
            },
            icon: const Icon(Icons.done_all, color: Colors.white, size: 18),
            label: const Text('Mark all read',
                style: TextStyle(color: Colors.white, fontSize: 12)),
          ),
        ],
      ),
      body: notifications.isEmpty
          ? const EmptyState(
              icon: Icons.notifications_none,
              title: 'No notifications yet',
              subtitle: 'You will see updates about your project here',
            )
          : ListView.separated(
              padding: const EdgeInsets.all(16),
              itemCount: notifications.length,
              separatorBuilder: (_, __) => const SizedBox(height: 4),
              itemBuilder: (context, index) {
                final notif = notifications[index];
                return NotificationTile(
                  notification: notif,
                  onTap: () {
                    if (!notif.isRead) {
                      notifProvider.markAsRead(notif.id);
                    }
                  },
                );
              },
            ),
    );
  }
}
