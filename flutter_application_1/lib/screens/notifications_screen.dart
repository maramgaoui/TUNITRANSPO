import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class NotificationsScreen extends StatefulWidget {
  const NotificationsScreen({super.key});

  @override
  State<NotificationsScreen> createState() => _NotificationsScreenState();
}

class _NotificationsScreenState extends State<NotificationsScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Notifications'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.notifications_none,
              size: 80,
              color: AppTheme.primaryTeal,
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucune notification pour le moment',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.mediumGrey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Vous recevrez des notifications pour vos trajets',
              style: TextStyle(
                fontSize: 14,
                color: AppTheme.mediumGrey,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}
