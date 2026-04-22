import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../controllers/auth_controller.dart';
import '../controllers/notification_controller.dart';
import '../firebase_runtime_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  if (Firebase.apps.isEmpty) {
    try {
      await Firebase.initializeApp(
        options: FirebaseRuntimeOptions.currentPlatform,
      );
    } on FirebaseException catch (e) {
      if (e.code != 'duplicate-app' && e.code != 'core/duplicate-app') {
        rethrow;
      }
    }
  }

  // Background isolate: keep lightweight work only.
  debugPrint('Background notification received: ${message.messageId}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;
  StreamSubscription<String>? _tokenRefreshSubscription;

  bool get _isMessagingSupported {
    if (kIsWeb) return false;

    // Firebase Messaging token APIs are not available on Windows/Linux.
    return defaultTargetPlatform == TargetPlatform.android ||
        defaultTargetPlatform == TargetPlatform.iOS ||
        defaultTargetPlatform == TargetPlatform.macOS;
  }

  Future<void> initialize() async {
    if (_initialized) return;

    if (!_isMessagingSupported) {
      debugPrint('Firebase Messaging is not supported on this platform. Skipping init.');
      _initialized = true;
      return;
    }

    await _requestPermissions();
    await _initializeToken();
    _registerTokenRefreshHandler();
    _registerForegroundHandler();
    _registerOpenedAppHandler();
    await _handleInitialMessage();

    _initialized = true;
  }

  Future<void> _requestPermissions() async {
    final settings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    debugPrint('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _initializeToken() async {
    try {
      final token = await _messaging.getToken();
      if (token != null && token.isNotEmpty) {
        await _saveTokenToCurrentUser(token);
      }
      if (kDebugMode) {
        debugPrint('FCM token initialized.');
      }
    } on MissingPluginException {
      // Defensive fallback for desktop targets where channel impl is absent.
      debugPrint('FCM getToken is not implemented on this platform.');
    } catch (e) {
      // Do not crash app startup if FCM token provisioning is temporarily
      // unavailable (for example after key restriction changes).
      debugPrint('FCM token initialization failed: $e');
    }
  }

  void _registerTokenRefreshHandler() {
    _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = _messaging.onTokenRefresh.listen((token) async {
      if (token.isEmpty) return;
      await _saveTokenToCurrentUser(token);
    });
  }

  Future<void> _saveTokenToCurrentUser(String token) async {
    final uid = AuthController.instance.currentUser?.uid;
    if (uid == null || uid.isEmpty) {
      return;
    }

    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmToken': token,
      }, SetOptions(merge: true));
    } catch (e) {
      debugPrint('Failed to persist FCM token: $e');
    }
  }

  void _registerForegroundHandler() {
    FirebaseMessaging.onMessage.listen((message) {
      debugPrint('Foreground notification received: ${message.messageId}');
      NotificationController.instance.addFromRemoteMessage(message);
    });
  }

  void _registerOpenedAppHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      debugPrint('Opened from notification: ${message.messageId}');
      NotificationController.instance.addFromRemoteMessage(message);
    });
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) return;

    debugPrint('Initial notification open: ${initialMessage.messageId}');
    NotificationController.instance.addFromRemoteMessage(initialMessage);
  }

  Future<void> dispose() async {
    await _tokenRefreshSubscription?.cancel();
    _tokenRefreshSubscription = null;
  }
}
