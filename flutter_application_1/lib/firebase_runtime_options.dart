import 'package:firebase_core/firebase_core.dart';

import 'firebase_options.dart';

class FirebaseRuntimeOptions {
  static const bool integrationTestMode = bool.fromEnvironment(
    'INTEGRATION_TEST_MODE',
    defaultValue: false,
  );

  static const String _apiKey = String.fromEnvironment('TEST_FIREBASE_API_KEY');
  static const String _appId = String.fromEnvironment('TEST_FIREBASE_APP_ID');
  static const String _messagingSenderId = String.fromEnvironment(
    'TEST_FIREBASE_MESSAGING_SENDER_ID',
  );
  static const String _projectId = String.fromEnvironment('TEST_FIREBASE_PROJECT_ID');
  static const String _storageBucket = String.fromEnvironment('TEST_FIREBASE_STORAGE_BUCKET');
  static const String _authDomain = String.fromEnvironment('TEST_FIREBASE_AUTH_DOMAIN');
  static const String _measurementId = String.fromEnvironment('TEST_FIREBASE_MEASUREMENT_ID');
  static const String _iosBundleId = String.fromEnvironment('TEST_FIREBASE_IOS_BUNDLE_ID');
  static const String _iosClientId = String.fromEnvironment('TEST_FIREBASE_IOS_CLIENT_ID');

  static bool get hasTestOverride =>
      _apiKey.isNotEmpty &&
      _appId.isNotEmpty &&
      _messagingSenderId.isNotEmpty &&
      _projectId.isNotEmpty;

  static FirebaseOptions get currentPlatform {
    if (!hasTestOverride) {
      return DefaultFirebaseOptions.currentPlatform;
    }

    return FirebaseOptions(
      apiKey: _apiKey,
      appId: _appId,
      messagingSenderId: _messagingSenderId,
      projectId: _projectId,
      storageBucket: _storageBucket.isEmpty ? null : _storageBucket,
      authDomain: _authDomain.isEmpty ? null : _authDomain,
      measurementId: _measurementId.isEmpty ? null : _measurementId,
      iosBundleId: _iosBundleId.isEmpty ? null : _iosBundleId,
      iosClientId: _iosClientId.isEmpty ? null : _iosClientId,
    );
  }
}