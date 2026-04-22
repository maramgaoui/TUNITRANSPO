import 'dart:convert';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuni_transport/models/notification_model.dart';

class NotificationController extends ChangeNotifier {
  NotificationController._();

  static final NotificationController instance = NotificationController._();
  static const String _storageKey = 'local_notifications_v1';
  static const String _l10nPrefix = 'l10n:';

  final List<NotificationModel> _notifications = [];
  bool _initialized = false;
  bool _isLoading = false; // Prevent concurrent operations

  Future<void> initialize() async {
    if (_initialized) return;
    if (_isLoading) return; // Prevent duplicate initialization

    _isLoading = true;
    try {
      await _loadFromStorage();
      await ensureSystemAnnouncement(); // Make await explicit
      _initialized = true;
    } catch (e) {
      debugPrint('[NotificationController] Initialization error: $e');
    } finally {
      _isLoading = false;
    }
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
    // Prevent duplicate notifications (by ID)
    if (_notifications.any((n) => n.id == notification.id)) {
      debugPrint('[NotificationController] Duplicate notification ignored: ${notification.id}');
      return;
    }

    _notifications.insert(0, notification);
    notifyListeners();
    _persistToStorage();
  }

  void addFromRemoteMessage(RemoteMessage message) {
    final data = message.data;
    
    // Extract notification data with proper fallbacks
    String title;
    String body;
    
    // Prefer notification payload, then data payload, then fallback to l10n tokens
    if (message.notification?.title != null && 
        message.notification!.title!.isNotEmpty) {
      title = message.notification!.title!;
    } else if (data['title'] != null && data['title'].toString().isNotEmpty) {
      title = data['title'].toString();
    } else {
      title = _l10nToken('newNotificationTitle');
    }
    
    if (message.notification?.body != null && 
        message.notification!.body!.isNotEmpty) {
      body = message.notification!.body!;
    } else if (data['body'] != null && data['body'].toString().isNotEmpty) {
      body = data['body'].toString();
    } else {
      body = _l10nToken('receivedNotificationBody');
    }
    
    final type = _typeFromString(data['type']?.toString());
    
    // Use messageId or generate a unique ID
    final id = message.messageId ?? 
               '${DateTime.now().millisecondsSinceEpoch}_${type.name}';

    addNotification(
      NotificationModel(
        id: id,
        title: title,
        body: body,
        type: type,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }

  void addExampleChatNotification(String username, String previewText) {
    addNotification(
      NotificationModel(
        id: 'example_chat_${DateTime.now().microsecondsSinceEpoch}',
        title: _l10nToken('newMessageNotification'),
        body: '$username: $previewText',
        type: NotificationType.chat,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }

  void addExampleJourneyNotification(String departure, String arrival) {
    addNotification(
      NotificationModel(
        id: 'example_journey_${DateTime.now().microsecondsSinceEpoch}',
        title: _l10nToken('newJourneyNotification'),
        body: '$departure → $arrival',
        type: NotificationType.journey,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }

  Future<void> ensureSystemAnnouncement() async {
    final hasAnnouncement = _notifications.any(
      (notification) => notification.type == NotificationType.system,
    );
    if (hasAnnouncement) return;

    addNotification(
      NotificationModel(
        id: 'system_announcement_${DateTime.now().microsecondsSinceEpoch}',
        title: _l10nToken('systemAnnouncementTitle'),
        body: _l10nToken('systemWelcomeBody'),
        type: NotificationType.system,
        timestamp: DateTime.now(),
        isRead: false,
      ),
    );
  }

  void markAsRead(String id) {
    final index = _notifications.indexWhere(
      (notification) => notification.id == id,
    );
    if (index == -1) return;
    
    if (_notifications[index].isRead) return; // Already read

    _notifications[index] = _notifications[index].copyWith(isRead: true);
    notifyListeners();
    _persistToStorage();
  }

  void markAllAsRead() {
    bool changed = false;
    for (var i = 0; i < _notifications.length; i++) {
      if (!_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      _persistToStorage();
    }
  }

  void markAllChatAsRead() {
    bool changed = false;
    for (var i = 0; i < _notifications.length; i++) {
      if (_notifications[i].type == NotificationType.chat &&
          !_notifications[i].isRead) {
        _notifications[i] = _notifications[i].copyWith(isRead: true);
        changed = true;
      }
    }
    if (changed) {
      notifyListeners();
      _persistToStorage();
    }
  }

  Future<void> deleteNotification(String id) async {
    final index = _notifications.indexWhere((n) => n.id == id);
    if (index == -1) return;
    
    _notifications.removeAt(index);
    notifyListeners();
    await _persistToStorage();
  }

  void clearAllNotifications() {
    if (_notifications.isEmpty) return;
    
    _notifications.clear();
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
            (json) => NotificationModel.fromJson(json),
          ),
        );
      // Don't notifyListeners() here - will be called after initialization
    } catch (e) {
      debugPrint('[NotificationController] Failed to load from storage: $e');
      // Ignore corrupt local cache and continue with empty state.
    }
  }

  Future<void> _persistToStorage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = _notifications.map((item) => item.toJson()).toList();
      await prefs.setString(_storageKey, jsonEncode(payload));
    } catch (e) {
      debugPrint('[NotificationController] Failed to persist to storage: $e');
    }
  }

  NotificationType _typeFromString(String? rawType) {
    if (rawType == null) return NotificationType.system;
    
    switch (rawType.toLowerCase()) {
      case 'chat':
        return NotificationType.chat;
      case 'journey':
        return NotificationType.journey;
      case 'system':
        return NotificationType.system;
      default:
        return NotificationType.system;
    }
  }
}