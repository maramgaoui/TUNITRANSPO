// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'package:tuni_transport/main.dart';
import 'package:tuni_transport/services/settings_service.dart';

void main() {
  test('TuniTransport app smoke test', () async {
    TestWidgetsFlutterBinding.ensureInitialized();
    SharedPreferences.setMockInitialValues({});

    // Initialize settings service for the test
    final settingsService = SettingsService();
    await settingsService.init();

    // Basic smoke test - verify app root can be created without throwing.
    expect(() => MyApp(settingsService: settingsService), returnsNormally);
  });
}
