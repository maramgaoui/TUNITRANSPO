import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuni_transport/controllers/auth_controller.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';
import 'package:tuni_transport/screens/chat_screen.dart';

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('ChatScreen', () {
    testWidgets('affiche empty state si aucun message', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final authController = AuthController(
        firebaseAuth: MockFirebaseAuth(signedIn: false),
        firestore: firestore,
      );

      await tester.pumpWidget(
        _buildTestApp(
          ChatScreen(
            firestore: firestore,
            authController: authController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Be the first to write!'), findsOneWidget);
    });

    testWidgets('input désactivé si non authentifié', (tester) async {
      final firestore = FakeFirebaseFirestore();
      final authController = AuthController(
        firebaseAuth: MockFirebaseAuth(signedIn: false),
        firestore: firestore,
      );

      await tester.pumpWidget(
        _buildTestApp(
          ChatScreen(
            firestore: firestore,
            authController: authController,
          ),
        ),
      );
      await tester.pumpAndSettle();

      expect(find.text('Sign in to participate'), findsOneWidget);
      expect(find.byType(TextField), findsNothing);
      expect(find.byIcon(Icons.send_rounded), findsNothing);
    });
  });
}
