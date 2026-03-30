import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Messages'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.chat_bubble_outline,
              size: 80,
              color: AppTheme.primaryTeal,
            ),
            const SizedBox(height: 20),
            const Text(
              'Aucun message pour le moment',
              style: TextStyle(
                fontSize: 16,
                color: AppTheme.mediumGrey,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              'Vos conversations apparaîtront ici',
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
