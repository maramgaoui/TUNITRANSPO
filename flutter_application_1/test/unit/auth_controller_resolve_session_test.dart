// ignore_for_file: subtype_of_sealed_class

import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:tuni_transport/controllers/auth_controller.dart';
import 'package:tuni_transport/models/session_result.dart';
import 'package:tuni_transport/models/user_model.dart';

class _MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

class _MockCollectionReference extends Mock
    implements CollectionReference<Map<String, dynamic>> {}

class _MockQuery extends Mock implements Query<Map<String, dynamic>> {}

void main() {
  group('AuthController.resolveSession hardening', () {
    late _MockFirebaseFirestore firestore;
    late _MockCollectionReference adminsCollection;
    late _MockQuery adminsQuery;

    setUp(() {
      SharedPreferences.setMockInitialValues(<String, Object>{});

      firestore = _MockFirebaseFirestore();
      adminsCollection = _MockCollectionReference();
      adminsQuery = _MockQuery();

      when(
        () => firestore.collection('admins'),
      ).thenReturn(adminsCollection);
      when(
        () => adminsCollection.where(
          any(),
          isEqualTo: any(named: 'isEqualTo'),
        ),
      ).thenReturn(adminsQuery);
      when(() => adminsQuery.limit(any())).thenReturn(adminsQuery);
    });

    test(
      'returns cached guest role when Firestore is transiently unavailable and cached state is banned',
      () async {
        when(
          () => adminsQuery.get(),
        ).thenThrow(
          FirebaseException(
            plugin: 'cloud_firestore',
            code: 'unavailable',
            message: 'Temporary backend outage',
          ),
        );

        const uid = 'u_banned_cached';
        final prefs = await SharedPreferences.getInstance();
        await prefs.setString(
          'auth.session.$uid',
          jsonEncode(<String, dynamic>{
            'role': SessionRole.guest.name,
            'accountStatus': 'banned',
            'cachedAt': DateTime.now().toIso8601String(),
          }),
        );

        final auth = MockFirebaseAuth(
          mockUser: MockUser(uid: uid, email: 'banned@tuni.tn'),
          signedIn: true,
        );

        final controller = AuthController(firebaseAuth: auth, firestore: firestore);

        final result = await controller.resolveSession(
          User(uid: uid, email: 'banned@tuni.tn'),
        );

        expect(result.role, SessionRole.guest);
        expect(auth.currentUser, isNotNull);
      },
    );

    test('returns cached user role when transient Firestore failure occurs', () async {
      when(
        () => adminsQuery.get(),
      ).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'deadline-exceeded',
          message: 'Network timeout',
        ),
      );

      const uid = 'u_cached_user';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'auth.session.$uid',
        jsonEncode(<String, dynamic>{
          'role': SessionRole.user.name,
          'accountStatus': 'active',
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );

      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid, email: 'user@tuni.tn'),
        signedIn: true,
      );

      final controller = AuthController(firebaseAuth: auth, firestore: firestore);

      final result = await controller.resolveSession(
        User(uid: uid, email: 'user@tuni.tn'),
      );

      expect(result.role, SessionRole.user);
      expect(auth.currentUser, isNotNull);
    });

    test('returns cached admin role when transient Firestore failure occurs', () async {
      when(
        () => adminsQuery.get(),
      ).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'unavailable',
          message: 'Temporary backend outage',
        ),
      );

      const uid = 'u_cached_admin';
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(
        'auth.session.$uid',
        jsonEncode(<String, dynamic>{
          'role': SessionRole.admin.name,
          'adminRole': 'super_admin',
          'adminMatricule': 'A001',
          'adminName': 'Admin Root',
          'accountStatus': 'active',
          'cachedAt': DateTime.now().toIso8601String(),
        }),
      );

      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid, email: 'admin@tuni.tn'),
        signedIn: true,
      );

      final controller = AuthController(firebaseAuth: auth, firestore: firestore);

      final result = await controller.resolveSession(
        User(uid: uid, email: 'admin@tuni.tn'),
      );

      expect(result.role, SessionRole.admin);
      expect(result.adminRole, 'super_admin');
      expect(auth.currentUser, isNotNull);
    });

    test('forces guest and signs out on definitive permission-denied failure', () async {
      when(
        () => adminsQuery.get(),
      ).thenThrow(
        FirebaseException(
          plugin: 'cloud_firestore',
          code: 'permission-denied',
          message: 'Rules denied read',
        ),
      );

      const uid = 'u_permission_denied';
      final auth = MockFirebaseAuth(
        mockUser: MockUser(uid: uid, email: 'user@tuni.tn'),
        signedIn: true,
      );

      final controller = AuthController(firebaseAuth: auth, firestore: firestore);

      final result = await controller.resolveSession(
        User(uid: uid, email: 'user@tuni.tn'),
      );

      expect(result.role, SessionRole.guest);
      expect(auth.currentUser, isNull);
    });
  });
}
