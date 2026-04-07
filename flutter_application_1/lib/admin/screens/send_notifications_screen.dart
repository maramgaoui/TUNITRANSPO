import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:go_router/go_router.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/theme/app_theme.dart';

class SendNotificationsScreen extends StatefulWidget {
  const SendNotificationsScreen({super.key});

  @override
  State<SendNotificationsScreen> createState() =>
      _SendNotificationsScreenState();
}

class _SendNotificationsScreenState extends State<SendNotificationsScreen> {
  final CollectionReference<Map<String, dynamic>> _notificationsRef =
      FirebaseFirestore.instance.collection('notifications');
  final CollectionReference<Map<String, dynamic>> _usersRef =
      FirebaseFirestore.instance.collection('users');

  final titleCtrl = TextEditingController();
  final messageCtrl = TextEditingController();
  bool _isSending = false;
  String selectedTarget = 'all'; // all, app_users, drivers

  Future<int> _estimateRecipients(String target) async {
    AggregateQuery query;
    if (target == 'drivers') {
      query = _usersRef.where('role', isEqualTo: 'driver').count();
    } else {
      query = _usersRef.count();
    }
    final snapshot = await query.get();
    return snapshot.count ?? 0;
  }

  Future<void> _sendNotification() async {
    final l10n = AppLocalizations.of(context)!;
    if (titleCtrl.text.isEmpty || messageCtrl.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(l10n.fillAllFields)),
      );
      return;
    }

    setState(() => _isSending = true);
    try {
      final recipients = await _estimateRecipients(selectedTarget);
      await _notificationsRef.add({
        'title': titleCtrl.text.trim(),
        'message': messageCtrl.text.trim(),
        'target': selectedTarget,
        'recipientsCount': recipients,
        'createdAt': FieldValue.serverTimestamp(),
      });

      if (!mounted) return;
      titleCtrl.clear();
      messageCtrl.clear();

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(l10n.notificationSavedForRecipients(recipients)),
        ),
      );
    } on FirebaseException catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(e.message ?? l10n.firestoreUpdateError)),
      );
    } finally {
      if (mounted) {
        setState(() => _isSending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.sendNotifications),
        backgroundColor: AppTheme.primaryTeal,
        foregroundColor: Colors.white,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/admin'),
        ),
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
                    Text(
                      l10n.composeNotification,
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
                        labelText: l10n.title,
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
                        labelText: l10n.content,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      l10n.recipients,
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
                              Text(l10n.allUsers),
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
                              Text(l10n.appUsers),
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
                              Text(l10n.drivers),
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
                        onPressed: _isSending ? null : _sendNotification,
                        icon: _isSending
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.send),
                        label: Text(_isSending
                            ? l10n.sendingInProgress
                            : l10n.sendNotificationAction),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),

            // History section
            Text(
              l10n.notificationsHistory,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
              stream: _notificationsRef
                  .orderBy('createdAt', descending: true)
                  .limit(50)
                  .snapshots(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snapshot.hasError) {
                  return Text(l10n.notificationsLoadError);
                }

                final docs = snapshot.data?.docs ?? [];
                if (docs.isEmpty) {
                  return Text(l10n.noNotificationSentYet);
                }

                return Column(
                  children: docs.map((doc) {
                    final data = doc.data();
                    final title = (data['title'] ?? '').toString();
                    final message = (data['message'] ?? '').toString();
                    final recipients = (data['recipientsCount'] ?? 0) as int;
                    final ts = data['createdAt'];
                    final sentAt =
                        ts is Timestamp ? ts.toDate() : DateTime.now();

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
                                    title,
                                    style: const TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                Text(
                                  _formatDate(sentAt),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    color: AppTheme.darkGrey,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 6),
                            Text(
                              message,
                              style: const TextStyle(fontSize: 13),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                const Icon(Icons.person, size: 16, color: AppTheme.mediumGrey),
                                const SizedBox(width: 4),
                                Text(
                                  l10n.recipientsCount(recipients),
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
                  }).toList(),
                );
              },
            ),
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
