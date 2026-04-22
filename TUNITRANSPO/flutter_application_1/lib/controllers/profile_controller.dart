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

      return _firestore.collection('users').doc(user.uid).snapshots().map((userDoc) {
        try {
          final userData = userDoc.data() ?? <String, dynamic>{};
          
          // Ensure required fields exist
          userData['uid'] = _getStringValue(userData['uid'], user.uid);
          userData['email'] = _getStringValue(userData['email'], user.email ?? '');
          
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

  // Helper to safely get string values
  String _getStringValue(dynamic value, String defaultValue) {
    if (value is String && value.isNotEmpty) return value;
    if (value != null) return value.toString();
    return defaultValue;
  }

  // Read current profile once, with a short exponential backoff for transient delays.
  Future<User?> getCurrentProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    const maxAttempts = 4;
    var delayMs = 150;
    Exception? lastError;

    for (var attempt = 1; attempt <= maxAttempts; attempt++) {
      try {
        final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();
        final userData = userDoc.data() ?? <String, dynamic>{};

        // Even if data is empty, return a basic user object
        userData['uid'] = _getStringValue(userData['uid'], firebaseUser.uid);
        userData['email'] = _getStringValue(userData['email'], firebaseUser.email ?? '');

        return User.fromMap(userData);
      } catch (e) {
        lastError = e is Exception ? e : Exception(e.toString());
        if (attempt == maxAttempts) {
          developer.log(
            'getCurrentProfile Error after $maxAttempts attempts: $lastError',
            name: 'ProfileController',
          );
          break;
        }
      }

      await Future.delayed(Duration(milliseconds: delayMs));
      delayMs *= 2;
    }

    // Return fallback user with basic info from Firebase Auth
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
      // Ensure UID matches current user
      final updatedProfile = profile.copyWith(uid: firebaseUser.uid);
      
      await _firestore
          .collection('users')
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

    // Prevent UID spoofing
    if (fields.containsKey('uid')) {
      developer.log('Attempt to update UID blocked', name: 'ProfileController');
      fields.remove('uid');
    }

    if (fields.isEmpty) return true; // Nothing to update

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

    // Validate new password strength
    if (newPassword.length < 6) {
      return 'Le nouveau mot de passe doit contenir au moins 6 caractères';
    }

    if (currentPassword == newPassword) {
      return 'Le nouveau mot de passe doit être différent de l\'ancien';
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
      
      // Optionally: Send email notification about password change
      await _sendPasswordChangeNotification(firebaseUser.email);
      
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
        case 'user-disabled':
          return 'Ce compte a été désactivé';
        case 'user-not-found':
          return 'Utilisateur non trouvé';
        default:
          return 'Échec du changement de mot de passe: ${e.message}';
      }
    } catch (e) {
      developer.log('Error changing password: $e', name: 'ProfileController');
      return 'Échec du changement de mot de passe';
    }
  }

  // Helper to send password change notification
  Future<void> _sendPasswordChangeNotification(String? email) async {
    try {
      // Implement email notification if needed
      // This could be a call to a cloud function or just local logging
      developer.log('Password changed for user: $email', name: 'ProfileController');
    } catch (e) {
      // Non-critical, don't fail the password change
      developer.log('Failed to send password change notification: $e', name: 'ProfileController');
    }
  }

  // Delete user account
  Future<String?> deleteAccount() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) {
      return 'Utilisateur non connecté';
    }

    try {
      // Delete user data from Firestore first
      await _firestore.collection('users').doc(firebaseUser.uid).delete();
      
      // Then delete the Firebase Auth user
      await firebaseUser.delete();
      
      return null; // Success
    } on firebase_auth.FirebaseAuthException catch (e) {
      developer.log('Error deleting account (${e.code}): ${e.message}', name: 'ProfileController');
      
      switch (e.code) {
        case 'requires-recent-login':
          return 'Session expirée. Veuillez vous reconnecter puis réessayer';
        default:
          return 'Échec de la suppression du compte';
      }
    } catch (e) {
      developer.log('Error deleting account: $e', name: 'ProfileController');
      return 'Échec de la suppression du compte';
    }
  }

  // Refresh user profile
  Future<void> refreshUserProfile() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return;

    try {
      await firebaseUser.reload();
      developer.log('User profile refreshed', name: 'ProfileController');
    } catch (e) {
      developer.log('Failed to refresh user profile: $e', name: 'ProfileController');
    }
  }

  // Check if user profile exists in Firestore
  Future<bool> profileExists() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return false;

    try {
      final doc = await _firestore.collection('users').doc(firebaseUser.uid).get();
      return doc.exists;
    } catch (e) {
      developer.log('Error checking profile existence: $e', name: 'ProfileController');
      return false;
    }
  }
}