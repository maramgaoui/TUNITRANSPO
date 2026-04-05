import 'package:flutter/material.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/theme/app_theme.dart';

class SendNotificationsScreen extends StatefulWidget {
  const SendNotificationsScreen({super.key});

  @override
  State<SendNotificationsScreen> createState() =>
      _SendNotificationsScreenState();
}

class _SendNotificationsScreenState extends State<SendNotificationsScreen> {
  final List<_Notification> sentNotifications = [
    _Notification(
      id: '1',
      title: 'Maintenance Metro',
      message: 'Fermeture du métro samedi pour maintenance',
      sentAt: DateTime.now().subtract(const Duration(days: 2)),
      recipients: 1250,
    ),
    _Notification(
      id: '2',
      title: 'Nouvelle ligne',
      message: 'Lancement de la nouvelle ligne express Tunis-Sfax',
      sentAt: DateTime.now().subtract(const Duration(days: 5)),
      recipients: 3400,
    ),
  ];

  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  String selectedTarget = 'all'; // all, app_users, drivers

  void _sendNotification() {
    if (titleCtrl.text.isEmpty || messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Remplissez tous les champs')),
      );
      return;
    }

    final newNotif = _Notification(
      id: DateTime.now().toString(),
      title: titleCtrl.text,
      message: messageCtrl.text,
      sentAt: DateTime.now(),
      recipients: selectedTarget == 'all'
          ? 5600
          : selectedTarget == 'app_users'
              ? 2100
              : 1500,
    );

    setState(() {
      sentNotifications.insert(0, newNotif);
    });

    titleCtrl.clear();
    messageCtrl.clear();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Notification envoyée à ${newNotif.recipients} utilisateurs',
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendNotifications),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Compose section
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: AppTheme.lightGrey),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Composer une notification',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: titleCtrl,
                      maxLength: 100,
                      decoration: InputDecoration(
                        labelText: 'Titre',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: messageCtrl,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        labelText: 'Contenu',
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    const Text(
                      'Destinataires',
                      style: TextStyle(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    DropdownButton<String>(
                      isExpanded: true,
                      value: selectedTarget,
                      items: [
                        DropdownMenuItem(
                          value: 'all',
                          child: Row(
                            children: [
                              const Icon(Icons.people,
                                  size: 18, color: AppTheme.primaryTeal),
                              const SizedBox(width: 8),
                              const Text('Tous les utilisateurs (5600)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'app_users',
                          child: Row(
                            children: [
                              const Icon(Icons.smartphone,
                                  size: 18, color: AppTheme.primaryTeal),
                              const SizedBox(width: 8),
                              const Text('Utilisateurs app (2100)'),
                            ],
                          ),
                        ),
                        DropdownMenuItem(
                          value: 'drivers',
                          child: Row(
                            children: [
                              const Icon(Icons.directions_car,
                                  size: 18, color: AppTheme.primaryTeal),
                              const SizedBox(width: 8),
                              const Text('Conducteurs (1500)'),
                            ],
                          ),
                        ),
                      ],
                      onChanged: (v) {
                        if (v != null) setState(() => selectedTarget = v);
                      },
                    ),
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.primaryTeal,
                          foregroundColor: Colors.white,
                          padding: const EdgeInsets.symmetric(vertical: 14),
                        ),
                        onPressed: _sendNotification,
                        icon: const Icon(Icons.send),
                        label: const Text('Envoyer la notification'),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // History section
            const Text(
              'Historique des notifications',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            ...sentNotifications.map((notif) {
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              notif.title,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Text(
                            _formatDate(notif.sentAt),
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.darkGrey,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        notif.message,
                        style: const TextStyle(fontSize: 13),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 8),
                      Row(
                        children: [
                          Icon(Icons.person,
                              size: 16, color: AppTheme.mediumGrey),
                          const SizedBox(width: 4),
                          Text(
                            '${notif.recipients} destinataires',
                            style: const TextStyle(
                              fontSize: 12,
                              color: AppTheme.mediumGrey,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inHours < 24) {
      return '${diff.inHours}h ago';
    } else if (diff.inDays < 7) {
      return '${diff.inDays}j ago';
    } else {
      return '${date.day}/${date.month}/${date.year}';
    }
  }

  @override
  void dispose() {
    titleCtrl.dispose();
    messageCtrl.dispose();
    super.dispose();
  }
}

class _Notification {
  final String id;
  final String title;
  final String message;
  final DateTime sentAt;
  final int recipients;

  _Notification({
    required this.id,
    required this.title,
    required this.message,
    required this.sentAt,
    required this.recipients,
  });
}
