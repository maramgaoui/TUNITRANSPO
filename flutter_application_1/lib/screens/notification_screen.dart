import 'package:flutter/material.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';

import '../controllers/notification_controller.dart';
import '../models/notification_model.dart';
import '../theme/app_theme.dart';

class NotificationScreen extends StatefulWidget {
  const NotificationScreen({super.key});

  @override
  State<NotificationScreen> createState() => _NotificationScreenState();
}

class _NotificationScreenState extends State<NotificationScreen> {
  NotificationController get _controller => NotificationController.instance;
  static const String _l10nPrefix = 'l10n:';

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

  String _resolveL10nToken(AppLocalizations l10n, String value) {
    if (!value.startsWith(_l10nPrefix)) {
      return value;
    }

    final key = value.substring(_l10nPrefix.length);
    switch (key) {
      case 'newNotificationTitle':
        return l10n.newNotificationTitle;
      case 'receivedNotificationBody':
        return l10n.receivedNotificationBody;
      case 'newMessageNotification':
        return l10n.newMessageNotification;
      case 'newJourneyNotification':
        return l10n.newJourneyNotification;
      case 'systemAnnouncementTitle':
        return l10n.systemAnnouncementTitle;
      case 'systemWelcomeBody':
        return l10n.systemWelcomeBody;
      default:
        return value;
    }
  }

  String _localizedTitle(BuildContext context, NotificationModel notification) {
    final l10n = AppLocalizations.of(context)!;

    final tokenResolved = _resolveL10nToken(l10n, notification.title);
    if (tokenResolved != notification.title) {
      return tokenResolved;
    }

    // Map known legacy/static titles to localization keys for dynamic language switching.
    switch (notification.title) {
      case 'Nouveau message':
      case 'New message':
        return l10n.newMessageNotification;
      case 'Nouveau trajet créé':
      case 'New journey created':
        return l10n.newJourneyNotification;
      case 'Annonce système':
      case 'System announcement':
        return l10n.systemAnnouncementTitle;
      case 'Nouvelle notification':
      case 'New notification':
        return l10n.newNotificationTitle;
      default:
        return notification.title;
    }
  }

  String _localizedBody(BuildContext context, NotificationModel notification) {
    final l10n = AppLocalizations.of(context)!;

    final tokenResolved = _resolveL10nToken(l10n, notification.body);
    if (tokenResolved != notification.body) {
      return tokenResolved;
    }

    // Keep message payloads untouched unless they match localizable defaults.
    switch (notification.body) {
      case 'Vous avez reçu une notification':
      case 'You received a notification':
        return l10n.receivedNotificationBody;
      case 'Bienvenue sur TuniTranspo. Bonne navigation!':
      case 'Welcome to TuniTranspo. Enjoy your trip!':
        return l10n.systemWelcomeBody;
      default:
        return notification.body;
    }
  }

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;

    // Respect inherited text direction so Arabic renders in RTL automatically.
    return Directionality(
      textDirection: Directionality.of(context),
      child: Scaffold(
        appBar: AppBar(
          title: Text(l10n.notifications),
          actions: [
            AnimatedBuilder(
              animation: _controller,
              builder: (context, _) {
                return Padding(
                  padding: const EdgeInsetsDirectional.only(end: 12),
                  child: Center(
                    child: Container(
                      padding: const EdgeInsetsDirectional.fromSTEB(10, 6, 10, 6),
                      decoration: BoxDecoration(
                        color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        l10n.unreadCountLabel(_controller.unreadCount),
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
        body: AnimatedBuilder(
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
                                            _localizedTitle(context, notification),
                                            style: TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w700,
                                              color: Theme.of(context)
                                                  .colorScheme
                                                  .onSurface,
                                            ),
                                          ),
                                        ),
                                        Text(
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
                                      _localizedBody(context, notification),
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
    );
  }
}
