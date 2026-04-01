import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../utils/validation_utils.dart';

class AuthController {
  final firebase_auth.FirebaseAuth _firebaseAuth =
      firebase_auth.FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn();

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
        developer.log('Error fetching user data: $e', name: 'AuthController');
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
    String? username,
  }) async {
    try {
      // Validate all fields on backend before saving
      final emailValidation = ValidationUtils.validateEmail(email);
      if (emailValidation != null) {
        throw Exception(emailValidation);
      }

      final firstNameValidation = ValidationUtils.validateName(firstName, 'Prénom');
      if (firstNameValidation != null) {
        throw Exception(firstNameValidation);
      }

      final lastNameValidation = ValidationUtils.validateName(lastName, 'Nom');
      if (lastNameValidation != null) {
        throw Exception(lastNameValidation);
      }

      final passwordValidation = ValidationUtils.validatePassword(password);
      if (passwordValidation != null) {
        throw Exception(passwordValidation);
      }

      if (username != null && username.isNotEmpty) {
        final usernameValidation = ValidationUtils.validateUsername(username);
        if (usernameValidation != null) {
          throw Exception(usernameValidation);
        }
      }

      // Create Firebase Auth user
      final userCredential = await _firebaseAuth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );

      final firebaseUser = userCredential.user;
      if (firebaseUser == null) {
        throw Exception('Impossible de créer le compte utilisateur');
      }

      // Create user model
      final user = User(
        uid: firebaseUser.uid,
        email: email,
        firstName: firstName,
        lastName: lastName,
        createdAt: DateTime.now(),
      );

      // Save user data to Firestore 'users' collection
      await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());

      // Always save profile with registration data to 'profiles' collection
      final profileData = {
        'uid': firebaseUser.uid,
        'email': email,
        'username': username, // Save username as-is (should not be empty if validation passed)
        'firstName': firstName,
        'lastName': lastName,
        'createdAt': DateTime.now(),
      };
      developer.log('Saving profile data: $profileData', name: 'AuthController');
      await _firestore.collection('profiles').doc(firebaseUser.uid).set(profileData);

      return user;
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('Sign up error: $e', name: 'AuthController');
      throw Exception(e.toString());
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
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('Sign in error: $e', name: 'AuthController');
      throw Exception('An error occurred during sign in. Please try again.');
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) {
        throw Exception('Google sign-in cancelled');
      }

      // Get authentication details
      final googleAuth = await googleUser.authentication;

      // Create credential for Firebase
      final credential = firebase_auth.GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );

      // Sign in with Firebase
      final userCredential = await _firebaseAuth.signInWithCredential(credential);
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Check if user already exists in Firestore
      final userDoc = await _firestore.collection('users').doc(firebaseUser.uid).get();

      if (userDoc.exists) {
        return User.fromMap(userDoc.data() ?? {});
      } else {
        // Create new user document
        final user = User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          firstName: googleUser.displayName?.split(' ').first ?? '',
          lastName: googleUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          createdAt: DateTime.now(),
        );

        // Save user data to Firestore
        await _firestore.collection('users').doc(firebaseUser.uid).set(user.toMap());

        // Create profile entry
        final profileData = {
          'uid': firebaseUser.uid,
          'email': firebaseUser.email,
          'firstName': googleUser.displayName?.split(' ').first ?? '',
          'lastName': googleUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          'photoUrl': googleUser.photoUrl,
          'createdAt': DateTime.now(),
        };
        await _firestore.collection('profiles').doc(firebaseUser.uid).set(profileData);

        return user;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('Google sign in error: $e', name: 'AuthController');
      throw Exception('An error occurred during Google sign in. Please try again.');
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      developer.log('Sign out error: $e', name: 'AuthController');
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
      developer.log('Update profile error: $e', name: 'AuthController');
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
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('Delete account error: $e', name: 'AuthController');
      throw Exception('Failed to delete account');
    }
  }

  // Send password reset email
  Future<void> sendPasswordResetEmail(String email) async {
    try {
      await _firebaseAuth.sendPasswordResetEmail(email: email);
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } catch (e) {
      developer.log('Send password reset email error: $e', name: 'AuthController');
      throw Exception('Impossible d\'envoyer l\'email. Vérifiez que votre adresse email est correcte.');
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    return Exception(switch (e.code) {
      'weak-password' => 'The password provided is too weak. Please use a stronger password.',
      'email-already-in-use' => 'This email is already registered. Please sign in or use a different email.',
      'invalid-email' => 'The email address is invalid. Please check and try again.',
      'user-disabled' => 'This user account has been disabled.',
      'user-not-found' => 'No account found with this email address.',
      'wrong-password' => 'The password is incorrect. Please try again.',
      'too-many-requests' => 'Too many login attempts. Please try again later.',
      _ => 'An authentication error occurred. Please try again.',
    });
  }
}
