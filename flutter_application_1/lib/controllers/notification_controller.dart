import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  NotificationController._();

  static final NotificationController instance = NotificationController._();
  static const String _storageKey = 'local_notifications_v1';
  static const String _l10nPrefix = 'l10n:';

  final List<NotificationModel> _notifications = [];
  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    await _loadFromStorage();
    ensureSystemAnnouncement();
    _initialized = true;
  }

  List<NotificationModel> get notifications =>
      List<NotificationModel>.unmodifiable(_notifications);

  int get unreadCount =>
      _notifications.where((notification) => !notification.isRead).length;

  int get unreadChatCount => _notifications
      .where(
        (notification) =>
            notification.type == NotificationType.chat && !notification.isRead,
      )
      .length;

  String _l10nToken(String key) => '$_l10nPrefix$key';

  void addNotification(NotificationModel notification) {
    _notifications.insert(0, notification);
    notifyListeners();
    _persistToStorage();
  }

  void addFromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    final title =
        message.notification?.title ??
        (data['title']?.toString() ?? _l10nToken('newNotificationTitle'));
    final body =
        message.notification?.body ??
        (data['body']?.toString() ?? _l10nToken('receivedNotificationBody'));
    final type = _typeFromString(data['type']?.toString());

    addNotification(
      NotificationModel(
        id:
            message.messageId ??
            DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addExampleChatNotification(String username, String previewText) {
    addNotification(
      NotificationModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _l10nToken('newMessageNotification'),
        body: '$username: $previewText',
        type: NotificationType.chat,
        timestamp: DateTime.now(),
      ),
    );
  }

  void addExampleJourneyNotification(String departure, String arrival) {
    addNotification(
      NotificationModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _l10nToken('newJourneyNotification'),
        body: '$departure → $arrival',
        type: NotificationType.journey,
        timestamp: DateTime.now(),
      ),
    );
  }

  void ensureSystemAnnouncement() {
    final hasAnnouncement = _notifications.any(
      (notification) => notification.type == NotificationType.system,
    );
    if (hasAnnouncement) return;

    addNotification(
      NotificationModel(
        id: DateTime.now().microsecondsSinceEpoch.toString(),
        title: _l10nToken('systemAnnouncementTitle'),
        body: _l10nToken('systemWelcomeBody'),
        type: NotificationType.system,
        timestamp: DateTime.now(),
      ),
    );
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index == -1) return;

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    _persistToStorage();
  }

  void markAllAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      _notifications[i] = _notifications[i].copyWith(isRead: true);
    }
    notifyListeners();
    _persistToStorage();
  }

  void markAllChatAsRead() {
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].type == NotificationType.chat &&
          !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
      }
    }
    notifyListeners();
    _persistToStorage();
  }

  Future<void> _loadFromStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null || raw.isEmpty) return;

    try {
      final decoded = jsonDecode(raw);
      if (decoded is! List) return;

      _notifications
        ..clear()
        ..addAll(
          decoded.whereType<Map<String, dynamic>>().map(
            NotificationModel.fromJson,
          ),
        );
      notifyListeners();
    } catch (_) {
      // Ignore corrupt local cache and continue with empty state.
    }
  }

  Future<void> _persistToStorage() async {
    final prefs = await SharedPreferences.getInstance();
    final payload = _notifications.map((item) => item.toJson()).toList();
    await prefs.setString(_storageKey, jsonEncode(payload));
  }

  NotificationType _typeFromString(String? rawType) {
    switch (rawType) {
      case 'chat':
        return NotificationType.chat;
      case 'journey':
        return NotificationType.journey;
      default:
        return NotificationType.system;
    }
  }
}
