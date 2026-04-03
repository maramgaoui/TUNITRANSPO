import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import '../controllers/notification_controller.dart';
import '../firebase_options.dart';

@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  // Background isolate: keep lightweight work only.
  print('Background notification: ${message.messageId} ${message.data}');
}

class NotificationService {
  NotificationService._();

  static final NotificationService instance = NotificationService._();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  bool _initialized = false;

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
    await _printToken();
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

    print('Notification permission status: ${settings.authorizationStatus}');
  }

  Future<void> _printToken() async {
    try {
      final token = await _messaging.getToken();
      print('FCM token: $token');
    } on MissingPluginException {
      // Defensive fallback for desktop targets where channel impl is absent.
      debugPrint('FCM getToken is not implemented on this platform.');
    }
  }

  void _registerForegroundHandler() {
    FirebaseMessaging.onMessage.listen((message) {
      print('Foreground notification: ${message.messageId} ${message.data}');
      NotificationController.instance.addFromRemoteMessage(message);
    });
  }

  void _registerOpenedAppHandler() {
    FirebaseMessaging.onMessageOpenedApp.listen((message) {
      print('Opened from notification: ${message.messageId} ${message.data}');
      NotificationController.instance.addFromRemoteMessage(message);
    });
  }

  Future<void> _handleInitialMessage() async {
    final initialMessage = await _messaging.getInitialMessage();
    if (initialMessage == null) return;

    print('Initial notification open: ${initialMessage.messageId} ${initialMessage.data}');
    NotificationController.instance.addFromRemoteMessage(initialMessage);
  }
}
