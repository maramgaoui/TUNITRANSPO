import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/user_model.dart';

class AuthController {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get current user stream
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((firebase_auth.User? user) async {
      if (user == null) return null;

      // Fetch user data from Firestore
      try {
        final userDoc = await _firestore.collection('users').doc(user.uid).get();
        if (userDoc.exists) {
          return User.fromMap(userDoc.data() ?? {});
        } else {
          // Create default user if not in Firestore
          return User(
            uid: user.uid,
            email: user.email ?? '',
            createdAt: DateTime.now(),
          );
        }
      } catch (e) {
        print('Error fetching user data: $e');
        return User(
          uid: user.uid,
          email: user.email ?? '',
          createdAt: DateTime.now(),
        );
      }
    });
  }

  // Get current user
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    return User(
      uid: firebaseUser.uid,
      email: firebaseUser.email ?? '',
      createdAt: DateTime.now(),
    );
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
  }) async {
    try {
      // Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to create user account');
      }

      // Create user model
      final user = User(
        uid: firebaseUser.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        createdAt: DateTime.now(),
      );

      // Save user data to Firestore
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Sign up error: $e');
      throw Exception('An error occurred during sign up. Please try again.');
    }
  }

  // Sign in with email and password
  Future<User?> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      final userCredential = await _firebaseAuth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Failed to sign in');
      }

      // Fetch user data from Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        return User.fromMap(userDoc.data() ?? {});
      } else {
        // Return basic user if not in Firestore
        return User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          createdAt: DateTime.now(),
        );
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Sign in error: $e');
      throw Exception('An error occurred during sign in. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      print('Sign out error: $e');
      throw Exception('Failed to sign out');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? firstName,
    String? lastName,
    String? photoUrl,
  }) async {
    try {
      final updateData = <String, dynamic>{
        'updatedAt': DateTime.now(),
      };

      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (photoUrl != null) updateData['photoUrl'] = photoUrl;

      await _firestore.collection('users').doc(uid).update(updateData);
    } catch (e) {
      print('Update profile error: $e');
      throw Exception('Failed to update profile');
    }
  }

  // Delete account
  Future<void> deleteAccount({required String uid}) async {
    try {
      // Delete user data from Firestore
      await _firestore.collection('users').doc(uid).delete();

      // Delete Firebase Auth user
      await _firebaseAuth.currentUser?.delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw Exception('Failed to delete account');
    } catch (e) {
      print('Delete account error: $e');
      throw Exception('Failed to delete account');
    }
  }

  // Reset password
  Future<void> resetPassword({required String email}) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      print('Firebase Auth Error: ${e.code} - ${e.message}');
      throw _handleAuthException(e);
    } catch (e) {
      print('Reset password error: $e');
      throw Exception('Failed to send password reset email');
    }
  }

  // Handle Firebase Auth exceptions
  String _handleAuthException(firebase_auth.FirebaseAuthException e) {
    switch (e.code) {
      case 'weak-password':
        return 'The password provided is too weak. Please use a stronger password.';
      case 'email-already-in-use':
        return 'This email is already registered. Please sign in or use a different email.';
      case 'invalid-email':
        return 'The email address is invalid. Please check and try again.';
      case 'user-disabled':
        return 'This user account has been disabled.';
      case 'user-not-found':
        return 'No account found with this email address.';
      case 'wrong-password':
        return 'The password is incorrect. Please try again.';
      case 'too-many-requests':
        return 'Too many login attempts. Please try again later.';
      default:
        return 'An authentication error occurred. Please try again.';
    }
  }
}
