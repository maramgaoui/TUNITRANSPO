import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:developer' as developer;
import '../models/profile_model.dart';

class ProfileController {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user profile stream with retry logic
  Stream<Profile?> get profileStream {
    return _firebaseAuth.authStateChanges().asyncMap((firebase_auth.User? user) async {
      if (user == null) return null;

      try {
        // Retry logic to ensure Firestore data is available
        Profile? profile;
        int retries = 0;
        const maxRetries = 5;
        const delayMs = 800;

        while (retries < maxRetries && profile == null) {
          try {
            // Wait before fetching
            await Future.delayed(Duration(milliseconds: delayMs));

            final userDoc = await _firestore.collection('users').doc(user.uid).get();
            final userData = userDoc.data() ?? {};

            developer.log(
              'Attempt ${retries + 1}: User data: $userData',
              name: 'ProfileController',
            );

            if (userData.isNotEmpty) {
              if (userData['uid'] == null || userData['uid'].toString().isEmpty) {
                userData['uid'] = user.uid;
              }
              if (userData['email'] == null || userData['email'].toString().isEmpty) {
                userData['email'] = user.email ?? '';
              }

              developer.log('Final user data: $userData', name: 'ProfileController');
              profile = Profile.fromMap(userData);
            }
          } catch (e) {
            developer.log('Retry $retries failed: $e', name: 'ProfileController');
          }

          if (profile == null) {
            retries++;
          }
        }

        // If still no data after retries, return empty profile
        if (profile == null) {
          developer.log('Max retries reached, returning empty profile', name: 'ProfileController');
          profile = Profile(
            uid: user.uid,
            email: user.email ?? '',
          );
        }

        return profile;
      } catch (e) {
        developer.log('Error in profileStream: $e', name: 'ProfileController');
        return Profile(
          uid: user.uid,
          email: user.email ?? '',
        );
      }
    });
  }

  // Get current profile once with retry logic
  Future<Profile?> getCurrentProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      // Retry logic to ensure Firestore data is available
      Profile? profile;
      int retries = 0;
      const maxRetries = 5;
      const delayMs = 800;

      while (retries < maxRetries && profile == null) {
        try {
          // Wait before fetching
          await Future.delayed(Duration(milliseconds: delayMs));

          final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
          final userData = userDoc.data() ?? {};

          developer.log(
            'getCurrentProfile Attempt ${retries + 1}: User data: $userData',
            name: 'ProfileController',
          );

          if (userData.isNotEmpty) {
            if (userData['uid'] == null || userData['uid'].toString().isEmpty) {
              userData['uid'] = firebaseUser.uid;
            }
            if (userData['email'] == null || userData['email'].toString().isEmpty) {
              userData['email'] = firebaseUser.email ?? '';
            }

            developer.log('getCurrentProfile Final user data: $userData', name: 'ProfileController');
            profile = Profile.fromMap(userData);
          }
        } catch (e) {
          developer.log('getCurrentProfile Retry $retries failed: $e', name: 'ProfileController');
        }

        if (profile == null) {
          retries++;
        }
      }

      // If still no data after retries, return empty profile
      if (profile == null) {
        developer.log('getCurrentProfile Max retries reached, returning empty profile', name: 'ProfileController');
        profile = Profile(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
        );
      }

      return profile;
    } catch (e) {
      developer.log('getCurrentProfile Error: $e', name: 'ProfileController');
      return null;
    }
  }

  // Update profile
  Future<bool> updateProfile(Profile profile) async {
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
