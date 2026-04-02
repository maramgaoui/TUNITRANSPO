import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'dart:developer' as developer;
import 'dart:io';
import '../models/profile_model.dart';

class ProfileController {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseStorage _firebaseStorage = FirebaseStorage.instance;

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
            final profileDoc = await _firestore.collection('profiles').doc(user.uid).get();

            final userData = userDoc.data() ?? {};
            final profileData = profileDoc.data() ?? {};

            developer.log('Attempt ${retries + 1}: User data: $userData', name: 'ProfileController');
            developer.log('Attempt ${retries + 1}: Profile data: $profileData', name: 'ProfileController');

            // Check if we got actual data
            if (userData.isNotEmpty || profileData.isNotEmpty) {
              final mergedData = {...userData, ...profileData};

              // Ensure critical fields
              if (mergedData['uid'] == null || mergedData['uid'].toString().isEmpty) {
                mergedData['uid'] = user.uid;
              }
              if (mergedData['email'] == null || mergedData['email'].toString().isEmpty) {
                mergedData['email'] = user.email ?? '';
              }

              developer.log('Final merged data: $mergedData', name: 'ProfileController');
              profile = Profile.fromMap(mergedData);
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
            createdAt: DateTime.now(),
          );
        }

        return profile;
      } catch (e) {
        developer.log('Error in profileStream: $e', name: 'ProfileController');
        return Profile(
          uid: user.uid,
          email: user.email ?? '',
          createdAt: DateTime.now(),
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
          final profileDoc = await _firestore.collection('profiles').doc(firebaseUser.uid).get();

          final userData = userDoc.data() ?? {};
          final profileData = profileDoc.data() ?? {};

          developer.log('getCurrentProfile Attempt ${retries + 1}: User data: $userData', name: 'ProfileController');
          developer.log('getCurrentProfile Attempt ${retries + 1}: Profile data: $profileData', name: 'ProfileController');

          // Check if we got actual data
          if (userData.isNotEmpty || profileData.isNotEmpty) {
            final mergedData = {...userData, ...profileData};

            // Ensure critical fields
            if (mergedData['uid'] == null || mergedData['uid'].toString().isEmpty) {
              mergedData['uid'] = firebaseUser.uid;
            }
            if (mergedData['email'] == null || mergedData['email'].toString().isEmpty) {
              mergedData['email'] = firebaseUser.email ?? '';
            }

            developer.log('getCurrentProfile Final merged data: $mergedData', name: 'ProfileController');
            profile = Profile.fromMap(mergedData);
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
          createdAt: DateTime.now(),
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

  // Upload profile photo
  Future<bool> uploadProfilePhoto(File imageFile) async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return false;

    try {
      final fileName = 'profile_photos/${firebaseUser.uid}_${DateTime.now().millisecondsSinceEpoch}';
      final ref = _firebaseStorage.ref().child(fileName);
      
      // Upload the file
      await ref.putFile(imageFile);
      
      // Get the download URL
      final photoUrl = await ref.getDownloadURL();
      
      // Update the profile with the new photoUrl
      await _firestore.collection('profiles').doc(firebaseUser.uid).set({
        'photoUrl': photoUrl,
        'updatedAt': DateTime.now(),
      }, SetOptions(merge: true));
      
      return true;
    } catch (e) {
      developer.log('Error uploading profile photo: $e', name: 'ProfileController');
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
