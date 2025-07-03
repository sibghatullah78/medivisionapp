import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'notification_provider.dart';
import 'app_menu_item.dart';

class AppMenuButton extends StatelessWidget {
  const AppMenuButton({super.key});

  @override
  Widget build(BuildContext context) {
    return PopupMenuButton(
      icon: const Icon(Icons.menu_outlined, color: Colors.black, size: 30),
      itemBuilder: (context) => [
        _buildNotificationItem(context),
      ],
    );
  }

  PopupMenuItem<AppMenuItem> _buildNotificationItem(BuildContext context) {
    final notificationProvider = context.watch<NotificationProvider>();
    return PopupMenuItem(
      child: ListTile(
        leading: Icon(notificationProvider.notificationsEnabled
            ? Icons.notifications_active
            : Icons.notifications_off),
        title: Text(notificationProvider.notificationsEnabled
            ? 'Disable Notifications'
            : 'Enable Notifications'),
        onTap: () => notificationProvider.toggleNotifications(
            !notificationProvider.notificationsEnabled),
      ),
    );
  }
}