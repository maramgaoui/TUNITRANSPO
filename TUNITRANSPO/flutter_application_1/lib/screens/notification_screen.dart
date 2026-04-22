import 'package:flutter/material.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/models/notification_model.dart';

import '../controllers/notification_controller.dart';
import '../theme/app_theme.dart';
import '../utils/notification_l10n.dart';
import '../widgets/app_header.dart';
import '../widgets/time_text.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationController get _controller => NotificationController.instance;

  String _formatTime(DateTime timestamp) {
    final now = DateTime.now();
    final isToday = now.year == timestamp.year &&
        now.month == timestamp.month &&
        now.day == timestamp.day;

    final hh = timestamp.hour.toString().padLeft(2, '0');
    final mm = timestamp.minute.toString().padLeft(2, '0');
    if (isToday) return '$hh:$mm';

    final dd = timestamp.day.toString().padLeft(2, '0');
    final mo = timestamp.month.toString().padLeft(2, '0');
    return '$dd/$mo $hh:$mm';
  }

  IconData _iconForType(NotificationType type) {
    switch (type) {
      case NotificationType.chat:
        return Icons.chat_bubble_outline;
      case NotificationType.journey:
        return Icons.route_outlined;
      case NotificationType.system:
        return Icons.campaign_outlined;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Respect inherited text direction so Arabic renders in RTL automatically.
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        body: Column(
          children: [
            AppHeader(
              title: l10n.notifications,
              leading: Icon(
                Icons.notifications,
                color: Theme.of(context).colorScheme.onPrimary,
                size: 28,
              ),
              trailing: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  final onPrimary = Theme.of(context).colorScheme.onPrimary;
                  return Container(
                    padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
                    decoration: BoxDecoration(
                      color: onPrimary.withValues(alpha: 0.16),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      l10n.unreadCountLabel(_controller.unreadCount),
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: onPrimary,
                      ),
                    ),
                  );
                },
              ),
            ),
            Expanded(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
            final items = _controller.notifications;

            if (items.isEmpty) {
              return Center(
                child: Text(
                  l10n.noNotificationsYet,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.mediumGrey,
                  ),
                ),
              );
            }

            return Column(
              children: [
                Padding(
                  padding: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 0),
                  child: Align(
                    alignment: AlignmentDirectional.centerEnd,
                    child: TextButton.icon(
                      onPressed: _controller.unreadCount == 0
                          ? null
                          : _controller.markAllAsRead,
                      icon: const Icon(Icons.done_all),
                      label: Text(l10n.markAllAsRead),
                    ),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: items.length,
                    itemBuilder: (context, index) {
                      final notification = items[index];
                      final isUnread = !notification.isRead;

                      return InkWell(
                        onTap: () => _controller.markAsRead(notification.id),
                        child: Container(
                          margin: const EdgeInsetsDirectional.fromSTEB(12, 6, 12, 6),
                          padding: const EdgeInsetsDirectional.fromSTEB(12, 12, 12, 12),
                          decoration: BoxDecoration(
                            color: isUnread
                                ? Theme.of(context)
                                    .colorScheme
                                    .primary
                                    .withValues(alpha: 0.08)
                                : Theme.of(context).colorScheme.surface,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isUnread
                                  ? Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.25)
                                  : Theme.of(context)
                                      .colorScheme
                                      .outlineVariant
                                      .withValues(alpha: 0.6),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Container(
                                width: 36,
                                height: 36,
                                decoration: BoxDecoration(
                                  color: Theme.of(context)
                                      .colorScheme
                                      .primary
                                      .withValues(alpha: 0.14),
                                  shape: BoxShape.circle,
                                ),
                                child: Icon(
                                  _iconForType(notification.type),
                                  size: 18,
                                  color: Theme.of(context).colorScheme.primary,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      children: [
                                        Expanded(
                                          child: Text(
                                            NotificationL10n.localizedTitle(l10n, notification),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                        ),
                                        TimeText(
                                          _formatTime(notification.timestamp),
                                          style: TextStyle(
                                            fontSize: 11,
                                            color: AppTheme.mediumGrey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      NotificationL10n.localizedBody(l10n, notification),
                                      style: TextStyle(
                                        fontSize: 13,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .onSurface
                                            .withValues(alpha: 0.82),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              if (isUnread)
                                Container(
                                  margin: const EdgeInsetsDirectional.only(start: 8, top: 4),
                                  width: 10,
                                  height: 10,
                                  decoration: BoxDecoration(
                                    color: Theme.of(context).colorScheme.primary,
                                    shape: BoxShape.circle,
                                  ),
                                ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
