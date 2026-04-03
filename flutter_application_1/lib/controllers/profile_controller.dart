import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';

class ProfileController {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Stream profile updates directly from Firestore to avoid retry delays.
  Stream<User?> get profileStream {
    return _firebaseAuth.authStateChanges().asyncExpand((firebase_auth.User? user) {
      if (user == null) return Stream<User?>.value(null);

      return _firestore.collection('users').doc(user.uid).snapshots().asyncMap((userDoc) async {
        try {
          final userData = userDoc.data() ?? <String, dynamic>{};
          userData['uid'] = (userData['uid']?.toString().isNotEmpty ?? false)
              ? userData['uid']
              : user.uid;
          userData['email'] = (userData['email']?.toString().isNotEmpty ?? false)
              ? userData['email']
              : (user.email ?? '');

          return User.fromMap(userData);
        } catch (e) {
          developer.log('Error mapping profile stream: $e', name: 'ProfileController');
          return User(
            uid: user.uid,
            email: user.email ?? '',
          );
        }
      });
    });
  }

  // Read current profile once, with a short exponential backoff for transient delays.
  Future<User?> getCurrentProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    const maxAttempts = 4;
    var delayMs = 150;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        final userData = userDoc.data() ?? <String, dynamic>{};

        if (userData.isNotEmpty || attempt == maxAttempts) {
          userData['uid'] = (userData['uid']?.toString().isNotEmpty ?? false)
              ? userData['uid']
              : firebaseUser.uid;
          userData['email'] = (userData['email']?.toString().isNotEmpty ?? false)
              ? userData['email']
              : (firebaseUser.email ?? '');

          return User.fromMap(userData);
        }
      } catch (e) {
        if (attempt == maxAttempts) {
          developer.log('getCurrentProfile Error after retries: $e', name: 'ProfileController');
          break;
        }
      }

      await Future.delayed(Duration(milliseconds: delayMs));
      delayMs *= 2;
    }

    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
    );
  }

  // Update profile
  Future<bool> updateProfile(User profile) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return false;

    try {
      await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .set(profile.toMap(), SetOptions(merge: true));
      return true;
    } catch (e) {
      developer.log('Error updating profile: $e', name: 'ProfileController');
      return false;
    }
  }

  // Update specific profile fields
  Future<bool> updateProfileFields(Map<String, dynamic> fields) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return false;

    try {
      await _firestore.collection('users').doc(firebaseUser.uid).set(
            fields,
            SetOptions(merge: true),
          );
      return true;
    } catch (e) {
      developer.log('Error updating profile fields: $e', name: 'ProfileController');
      return false;
    }
  }

  // Change password. Returns null on success, otherwise an error message.
  Future<String?> changePassword(String currentPassword, String newPassword) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return 'Utilisateur non connecté';
    }

    try {
      // Re-authenticate user before changing password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: firebaseUser.email ?? '',
        password: currentPassword,
      );

      await firebaseUser.reauthenticateWithCredential(credential);

      // Update password
      await firebaseUser.updatePassword(newPassword);
      return null;
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log(
        'Error changing password (${e.code}): ${e.message}',
        name: 'ProfileController',
      );

      switch (e.code) {
        case 'wrong-password':
        case 'invalid-credential':
          return 'Le mot de passe actuel est incorrect';
        case 'weak-password':
          return 'Le nouveau mot de passe est trop faible';
        case 'requires-recent-login':
          return 'Session expirée. Veuillez vous reconnecter puis réessayer';
        case 'too-many-requests':
          return 'Trop de tentatives. Veuillez réessayer plus tard';
        default:
          return 'Échec du changement de mot de passe';
      }
    } catch (e) {
      developer.log('Error changing password: $e', name: 'ProfileController');
      return 'Échec du changement de mot de passe';
    }
  }
}
