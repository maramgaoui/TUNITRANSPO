import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/profile_model.dart';

class ProfileController {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user profile stream
  Stream<Profile?> get profileStream {
    return _firebaseAuth.authStateChanges().asyncMap((firebase_auth.User? user) async {
      if (user == null) return null;

      try {
        final profileDoc =
            await _firestore.collection('profiles').doc(user.uid).get();
        if (profileDoc.exists) {
          return Profile.fromMap(profileDoc.data() ?? {});
        } else {
          // Create default profile if not in Firestore
          return Profile(
            uid: user.uid,
            email: user.email ?? '',
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        developer.log('Error fetching profile data: $e', name: 'ProfileController');
        return Profile(
          uid: user.uid,
          email: user.email ?? '',
          createdAt: DateTime.now(),
        );
      }
    });
  }

  // Get current profile once
  Future<Profile?> getCurrentProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final profileDoc =
          await _firestore.collection('profiles').doc(firebaseUser.uid).get();
      if (profileDoc.exists) {
        return Profile.fromMap(profileDoc.data() ?? {});
      } else {
        return Profile(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          createdAt: DateTime.now(),
        );
      }
    } catch (e) {
      developer.log('Error fetching profile: $e', name: 'ProfileController');
      return null;
    }
  }

  // Update profile
  Future<bool> updateProfile(Profile profile) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return false;

    try {
      final updatedProfile = profile.copyWith(updatedAt: DateTime.now());
      await _firestore
          .collection('profiles')
          .doc(firebaseUser.uid)
          .set(updatedProfile.toMap(), SetOptions(merge: true));
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
      fields['updatedAt'] = DateTime.now();
      await _firestore.collection('profiles').doc(firebaseUser.uid).set(
            fields,
            SetOptions(merge: true),
          );
      return true;
    } catch (e) {
      developer.log('Error updating profile fields: $e', name: 'ProfileController');
      return false;
    }
  }

  // Delete profile photo
  Future<bool> deleteProfilePhoto() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return false;

    try {
      await _firestore.collection('profiles').doc(firebaseUser.uid).update({
        'photoUrl': null,
        'updatedAt': DateTime.now(),
      });
      return true;
    } catch (e) {
      developer.log('Error deleting profile photo: $e', name: 'ProfileController');
      return false;
    }
  }

  // Change password
  Future<bool> changePassword(String currentPassword, String newPassword) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return false;

    try {
      // Re-authenticate user before changing password
      final credential = firebase_auth.EmailAuthProvider.credential(
        email: firebaseUser.email ?? '',
        password: currentPassword,
      );

      await firebaseUser.reauthenticateWithCredential(credential);

      // Update password
      await firebaseUser.updatePassword(newPassword);
      return true;
    } catch (e) {
      developer.log('Error changing password: $e', name: 'ProfileController');
      return false;
    }
  }
}
