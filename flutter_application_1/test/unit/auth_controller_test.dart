import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuni_transport/controllers/auth_controller.dart';
import 'package:tuni_transport/models/session_result.dart';
import 'package:tuni_transport/models/user_model.dart';

void main() {
  group('AuthController', () {
    test('resolveSession retourne SessionRole.admin si doc existe dans admins', () async {
      final firestore = FakeFirebaseFirestore();
      final mockUser = MockUser(uid: 'u_admin', email: 'admin@tuni.tn');
      final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await firestore.collection('admins').doc('admin_doc').set({
        'email': 'admin@tuni.tn',
        'role': 'super_admin',
        'matricule': 'A001',
        'name': 'Admin Root',
      });

      final controller = AuthController(
        firebaseAuth: auth,
        firestore: firestore,
      );

      final result = await controller.resolveSession(
        User(uid: 'u_admin', email: 'admin@tuni.tn'),
      );

      expect(result.role, SessionRole.admin);
      expect(result.isAdmin, isTrue);
      expect(result.adminRole, 'super_admin');
    });

    test('resolveSession retourne SessionRole.guest si user est banned', () async {
      final firestore = FakeFirebaseFirestore();
      final mockUser = MockUser(uid: 'u_banned', email: 'banned@tuni.tn');
      final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await firestore.collection('users').doc('u_banned').set({
        'uid': 'u_banned',
        'email': 'banned@tuni.tn',
        'status': 'banned',
        'banUntil': Timestamp.fromDate(
          DateTime.now().add(const Duration(days: 2)),
        ),
      });

      final controller = AuthController(
        firebaseAuth: auth,
        firestore: firestore,
      );

      final result = await controller.resolveSession(
        User(uid: 'u_banned', email: 'banned@tuni.tn'),
      );

      expect(result.role, SessionRole.guest);
      expect(result.isGuest, isTrue);
    });

    test('resolveSession utilise le cache < 5 min', () async {
      final firestore = FakeFirebaseFirestore();
      final mockUser = MockUser(uid: 'u_cache', email: 'cache@tuni.tn');
      final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await firestore.collection('users').doc('u_cache').set({
        'uid': 'u_cache',
        'email': 'cache@tuni.tn',
        'status': 'active',
      });

      final controller = AuthController(
        firebaseAuth: auth,
        firestore: firestore,
      );

      final first = await controller.resolveSession(
        User(uid: 'u_cache', email: 'cache@tuni.tn'),
      );
      expect(first.role, SessionRole.user);

      // If cache works, this new admin doc should not affect immediate result.
      await firestore.collection('admins').doc('late_admin').set({
        'email': 'cache@tuni.tn',
        'role': 'admin',
        'matricule': 'A777',
      });

      final second = await controller.resolveSession(
        User(uid: 'u_cache', email: 'cache@tuni.tn'),
      );
      expect(second.role, SessionRole.user);
    });

    test('signInWithEmail lève une exception si account blocked', () async {
      final firestore = FakeFirebaseFirestore();
      final mockUser = MockUser(uid: 'u_blocked', email: 'blocked@tuni.tn');
      final auth = MockFirebaseAuth(mockUser: mockUser, signedIn: true);

      await firestore.collection('users').doc('u_blocked').set({
        'uid': 'u_blocked',
        'email': 'blocked@tuni.tn',
        'status': 'blocked',
      });

      final controller = AuthController(
        firebaseAuth: auth,
        firestore: firestore,
      );

      expect(
        () => controller.signInWithEmail(
          email: 'blocked@tuni.tn',
          password: 'any-password',
        ),
        throwsA(
          isA<Exception>().having(
            (e) => e.toString(),
            'message',
            contains('permanently blocked'),
          ),
        ),
      );
    });
  });
}
