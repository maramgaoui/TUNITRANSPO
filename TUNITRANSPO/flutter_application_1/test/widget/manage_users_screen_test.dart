import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuni_transport/admin/screens/manage_users_screen.dart';
import 'package:tuni_transport/l10n/app_localizations.dart';

Future<void> _seedUser(
  FirebaseFirestore firestore,
  String id, {
  required String username,
  required String email,
  String status = 'active',
}) {
  return firestore.collection('users').doc(id).set({
    'uid': id,
    'username': username,
    'email': email,
    'status': status,
    'avatarId': 'avatar-01',
  });
}

Widget _buildTestApp(Widget child) {
  return MaterialApp(
    locale: const Locale('en'),
    localizationsDelegates: AppLocalizations.localizationsDelegates,
    supportedLocales: AppLocalizations.supportedLocales,
    home: child,
  );
}

void main() {
  group('ManageUsersScreen', () {
    testWidgets('affiche loading indicator pendant chargement stream', (tester) async {
      final firestore = FakeFirebaseFirestore();

      await tester.pumpWidget(
        _buildTestApp(
          ManageUsersScreen(
            firestore: firestore,
            initialLoadDelay: const Duration(milliseconds: 300),
          ),
        ),
      );

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();
    });

    testWidgets('filtre par status fonctionne', (tester) async {
      final firestore = FakeFirebaseFirestore();

      await _seedUser(
        firestore,
        'u_active',
        username: 'active_user',
        email: 'active@tuni.tn',
        status: 'active',
      );
      await _seedUser(
        firestore,
        'u_blocked',
        username: 'blocked_user',
        email: 'blocked@tuni.tn',
        status: 'blocked',
      );

      await tester.pumpWidget(
        _buildTestApp(ManageUsersScreen(firestore: firestore, pageSize: 10)),
      );
      await tester.pumpAndSettle();

      await tester.tap(find.text('Blocked'));
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 350));
      await tester.pumpAndSettle();

      expect(find.text('blocked_user'), findsOneWidget);
      expect(find.text('active_user'), findsNothing);
    });
  });
}
