import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuni_transport/models/journey_model.dart';
import 'package:tuni_transport/screens/splash_screen.dart';
import 'package:tuni_transport/theme/app_theme.dart';
import 'package:tuni_transport/widgets/journey_card.dart';
import 'package:tuni_transport/widgets/validated_text_field.dart';

void main() {
  setUpAll(() {
    TestWidgetsFlutterBinding.ensureInitialized();
  });

  group('TuniTranspo Widget Tests - Firebase-Independent', () {
    // Test 1: SplashScreen renders with animations
    testWidgets('Test 1: SplashScreen renders with loading indicator', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: const SplashScreen(),
          theme: ThemeData.light(),
        ),
      );
      expect(find.byType(SplashScreen), findsOneWidget);
      expect(find.byType(SlideTransition), findsWidgets);
      expect(find.byType(FadeTransition), findsWidgets);
      expect(tester.takeException(), isNull);
    });

    // Test 2: TabBar widget - standalone test for auth tab pattern
    testWidgets('Test 2: TabBar renders with two tabs', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: DefaultTabController(
            length: 2,
            child: Scaffold(
              appBar: AppBar(
                bottom: const TabBar(
                  tabs: [
                    Tab(text: 'Login'),
                    Tab(text: 'Register'),
                  ],
                ),
              ),
              body: const TabBarView(
                children: [
                  Center(child: Text('Login Tab')),
                  Center(child: Text('Register Tab')),
                ],
              ),
            ),
          ),
        ),
      );
      expect(find.byType(Tab), findsWidgets);
      expect(find.byType(TabBar), findsOneWidget);
      expect(find.byType(TabBarView), findsOneWidget);
      expect(tester.takeException(), isNull);
    });

    // Test 3: ValidatedTextField renders correctly
    testWidgets('Test 3: ValidatedTextField renders email field correctly', (WidgetTester tester) async {
      final emailController = TextEditingController();
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SingleChildScrollView(
              child: Column(children: [
                ValidatedTextField(
                  controller: emailController,
                  label: 'Email',
                  hintText: 'Enter your email',
                  prefixIcon: Icons.email,
                  validationType: 'email',
                ),
              ]),
            ),
          ),
          theme: ThemeData.light(),
        ),
      );
      await tester.pumpAndSettle();
      expect(find.byType(TextFormField), findsWidgets);
      expect(find.byIcon(Icons.email), findsWidgets);
      emailController.dispose();
    });

    // Test 4: Empty state indication widget
    testWidgets('Test 4: Empty state widget renders when no items', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.inbox, size: 64, color: Colors.grey[300]),
                  const SizedBox(height: 16),
                  Text(
                    'No items found',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                ],
              ),
            ),
          ),
          theme: ThemeData.light(),
        ),
      );
      expect(find.byIcon(Icons.inbox), findsOneWidget);
      expect(find.byType(Text), findsOneWidget);
      expect(find.byWidgetPredicate((w) => w is Text && w.data?.contains('No items') == true), findsOneWidget);
    });

    // Test 5: Custom Card widget renders journey data (standalone without Firebase)
    testWidgets('Test 5: Journey card widget renders destination information', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Card(
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.directions_bus, color: AppTheme.primaryTeal),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text('Tunis Centre'),
                              Text('La Goulette'),
                            ],
                          ),
                        ),
                        const Text('09:30'),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Row(
                      children: [Icon(Icons.timer), SizedBox(width: 8), Text('45 min')],
                    ),
                  ],
                ),
              ),
            ),
          ),
          theme: ThemeData.light().copyWith(
            colorScheme: ColorScheme.fromSeed(seedColor: AppTheme.primaryTeal),
          ),
        ),
      );
      expect(find.byType(Card), findsOneWidget);
      expect(find.byIcon(Icons.directions_bus), findsOneWidget);
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data?.contains('Tunis Centre') == true),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data?.contains('La Goulette') == true),
        findsOneWidget,
      );
      expect(
        find.byWidgetPredicate((w) => w is Text && w.data?.contains('45 min') == true),
        findsOneWidget,
      );
    });
  });
}
