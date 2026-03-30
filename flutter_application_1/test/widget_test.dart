// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';

import 'package:tuni_transport/main.dart';
import 'package:tuni_transport/services/settings_service.dart';

void main() {
  testWidgets('TuniTransport app smoke test', (WidgetTester tester) async {
    // Initialize settings service for the test
    final settingsService = SettingsService();
    // Note: In a real test, you'd mock SharedPreferences to avoid actual storage
    
    // Build our app and trigger a frame.
    await tester.pumpWidget(MyApp(settingsService: settingsService));

    // Basic smoke test - verify the app builds without errors
    expect(find.byType(MyApp), findsOneWidget);
  });
}
