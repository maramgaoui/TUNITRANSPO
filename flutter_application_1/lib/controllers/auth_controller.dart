import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'dart:developer' as developer;
import '../models/user_model.dart';
import '../models/session_result.dart';
import '../utils/validation_utils.dart';

class AuthController {
  AuthController({
    firebase_auth.FirebaseAuth? firebaseAuth,
    FirebaseFirestore? firestore,
    GoogleSignIn? googleSignIn,
  }) : _firebaseAuth = firebaseAuth ?? firebase_auth.FirebaseAuth.instance,
       _firestore = firestore ?? FirebaseFirestore.instance,
       _googleSignIn = googleSignIn;

  static final AuthController instance = AuthController();
  static const Duration _authStreamTtl = Duration(minutes: 5);
  static const Duration _sessionTtl = Duration(minutes: 5);

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  GoogleSignIn? _googleSignIn;
  SessionResult? _cachedSession;
  DateTime? _sessionCachedAt;
  String? _cachedSessionUid;
  User? _cachedAuthStreamUser;
  DateTime? _authStreamCachedAt;
  String? _cachedAuthStreamUid;

  GoogleSignIn get _googleSignInClient => _googleSignIn ??= GoogleSignIn();

  static const String _blockedMessage =
      'Your account has been permanently blocked.';

  void _invalidateAuthStreamCache() {
    _cachedAuthStreamUser = null;
    _authStreamCachedAt = null;
    _cachedAuthStreamUid = null;
  }

  void _cacheAuthStreamUser(String uid, User resolvedUser) {
    _cachedAuthStreamUser = resolvedUser;
    _authStreamCachedAt = DateTime.now();
    _cachedAuthStreamUid = uid;
  }

  void _invalidateSessionCache() {
    _cachedSession = null;
    _sessionCachedAt = null;
    _cachedSessionUid = null;
  }

  void _cacheSession(String uid, SessionResult session) {
    _cachedSession = session;
    _sessionCachedAt = DateTime.now();
    _cachedSessionUid = uid;
  }

  // Get current user stream
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((
      firebase_auth.User? user,
    ) async {
      if (user == null) {
        _invalidateAuthStreamCache();
        return null;
      }

      if (_cachedAuthStreamUser != null &&
          _cachedAuthStreamUid == user.uid &&
          _authStreamCachedAt != null &&
          DateTime.now().difference(_authStreamCachedAt!) < _authStreamTtl) {
        return _cachedAuthStreamUser;
      }

      // Ban logic on app open: if banUntil has expired, automatically reactivate user.
      // If user is still blocked/banned, sign out to prevent app access.
      try {
        final accessError = await _validateAndNormalizeUserAccess(
          uid: user.uid,
          enforceRestriction: true,
        );
        if (accessError != null) {
          _invalidateAuthStreamCache();
          await _firebaseAuth.signOut();
          return null;
        }
      } catch (e) {
        // Offline/temporary Firestore failures should not break auth stream
        // delivery or leave the app in a blank routing state.
        developer.log(
          'Skipping access normalization due to transient error: $e',
          name: 'AuthController',
        );
      }

      // Fetch user data from Firestore
      try {
        final userDoc = await _firestore
            .collection('users')
            .doc(user.uid)
            .get();
        if (userDoc.exists) {
          final resolvedUser = User.fromMap(userDoc.data() ?? {});
          _cacheAuthStreamUser(user.uid, resolvedUser);
          return resolvedUser;
        } else {
          // Create default user if not in Firestore
          final resolvedUser = User(uid: user.uid, email: user.email ?? '');
          _cacheAuthStreamUser(user.uid, resolvedUser);
          return resolvedUser;
        }
      } catch (e) {
        developer.log('Error fetching user data: $e', name: 'AuthController');
        final resolvedUser = User(uid: user.uid, email: user.email ?? '');
        _cacheAuthStreamUser(user.uid, resolvedUser);
        return resolvedUser;
      }
    });
  }

  // Get current user (uid + email only — use fetchCurrentUser() when profile fields are needed)
  User? get currentUser {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    return User(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
  }

  // Fetch full user profile from Firestore.
  // Returns a minimal User on Firestore errors so callers are never blocked.
  Future<User?> fetchCurrentUser() async {
    final firebaseUser = _firebaseAuth.currentUser;
    if (firebaseUser == null) return null;

    try {
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();
      if (userDoc.exists) {
        return User.fromMap(userDoc.data() ?? {});
      }
    } catch (e) {
      developer.log('Error fetching current user: $e', name: 'AuthController');
    }
    return User(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
  }

  // Sign up with email and password
  Future<User?> signUpWithEmail({
    required String email,
    required String password,
    required String firstName,
    required String lastName,
    String? username,
    String? avatarId,
  }) async {
    try {
      // Validate all fields on backend before saving
      final emailValidation = ValidationUtils.validateEmail(email);
      if (emailValidation != null) {
        throw Exception(emailValidation);
      }

      final firstNameValidation = ValidationUtils.validateName(
        firstName,
        'Prénom',
      );
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
        username: username,
        firstName: firstName,
        lastName: lastName,
        avatarId: avatarId,
      );

      // Save full account + profile data in one users document
      final userData = user.toMap();
      userData['status'] = 'active';
      userData['banUntil'] = null;
      developer.log('Saving user data: $userData', name: 'AuthController');
      await _firestore.collection('users').doc(firebaseUser.uid).set(userData);

      _invalidateSessionCache();
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

      final accessError = await _validateAndNormalizeUserAccess(
        uid: firebaseUser.uid,
        enforceRestriction: true,
      );
      if (accessError != null) {
        await _firebaseAuth.signOut();
        throw Exception(accessError);
      }

      // Fetch user data from Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        _invalidateSessionCache();
        return User.fromMap(userDoc.data() ?? {});
      } else {
        // Return basic user if not in Firestore
        _invalidateSessionCache();
        return User(uid: firebaseUser.uid, email: firebaseUser.email ?? '');
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on Exception {
      // Re-throw ban/block messages and other known exceptions as-is.
      rethrow;
    } catch (e) {
      developer.log('Sign in error: $e', name: 'AuthController');
      throw Exception('An error occurred during sign in. Please try again.');
    }
  }

  // Sign in with Google
  Future<User?> signInWithGoogle() async {
    try {
      // Trigger Google Sign-In flow
      final googleUser = await _googleSignInClient.signIn();
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
      final userCredential = await _firebaseAuth.signInWithCredential(
        credential,
      );
      final firebaseUser = userCredential.user;

      if (firebaseUser == null) {
        throw Exception('Failed to create Firebase user');
      }

      // Check if user already exists in Firestore
      final userDoc = await _firestore
          .collection('users')
          .doc(firebaseUser.uid)
          .get();

      if (userDoc.exists) {
        final accessError = await _validateAndNormalizeUserAccess(
          uid: firebaseUser.uid,
          enforceRestriction: true,
        );
        if (accessError != null) {
          await _firebaseAuth.signOut();
          throw Exception(accessError);
        }
        _invalidateSessionCache();
        return User.fromMap(userDoc.data() ?? {});
      } else {
        // Create new user document
        final user = User(
          uid: firebaseUser.uid,
          email: firebaseUser.email ?? '',
          username: null,
          firstName: googleUser.displayName?.split(' ').first ?? '',
          lastName: googleUser.displayName?.split(' ').skip(1).join(' ') ?? '',
          avatarId: 'avatar-01',
        );

        final userData = user.toMap();
        userData['status'] = 'active';
        userData['banUntil'] = null;
        await _firestore
            .collection('users')
            .doc(firebaseUser.uid)
            .set(userData);

        _invalidateSessionCache();
        return user;
      }
    } on firebase_auth.FirebaseAuthException catch (e) {
      throw _handleAuthException(e);
    } on Exception {
      rethrow;
    } catch (e) {
      developer.log('Google sign in error: $e', name: 'AuthController');
      throw Exception(
        'An error occurred during Google sign in. Please try again.',
      );
    }
  }

  /// Resolves the role and ban status of the currently signed-in user.
  /// Returns whether the user should be treated as guest, user, or admin.
  Future<SessionResult> resolveSession(User current) async {
    if (current.uid.isEmpty) {
      _invalidateSessionCache();
      return const SessionResult(role: SessionRole.guest);
    }

    if (_cachedSession != null &&
        _sessionCachedAt != null &&
        _cachedSessionUid == current.uid &&
        DateTime.now().difference(_sessionCachedAt!) < _sessionTtl) {
      return _cachedSession!;
    }

    try {
      final email = current.email.trim();
      QuerySnapshot<Map<String, dynamic>> adminSnapshot;

      // 1) Primary lookup by email.
      if (email.isNotEmpty) {
        adminSnapshot = await _firestore
            .collection('admins')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
      } else {
        adminSnapshot = await _firestore
        .collection('admins')
        .where('uid', isEqualTo: current.uid)
        .limit(1)
        .get();
      }

      // 2) Fallback lookup by Firebase uid.
      if (adminSnapshot.docs.isEmpty) {
        adminSnapshot = await _firestore
            .collection('admins')
            .where('uid', isEqualTo: current.uid)
            .limit(1)
            .get();
      }

      // 3) Compatibility fallback for legacy synthetic admin emails: <matricule>@admin.local
      if (adminSnapshot.docs.isEmpty &&
          email.isNotEmpty &&
          email.toLowerCase().endsWith('@admin.local')) {
        final matricule = email.split('@').first.trim();
        if (matricule.isNotEmpty) {
          adminSnapshot = await _firestore
              .collection('admins')
              .where('matricule', isEqualTo: matricule)
              .limit(1)
              .get();
        }
      }

      if (adminSnapshot.docs.isNotEmpty) {
        final adminData = adminSnapshot.docs.first.data();
        final result = SessionResult(
          role: SessionRole.admin,
          adminRole: adminData['role'] as String?,
          adminMatricule: (adminData['matricule'] ?? '').toString(),
          adminName: adminData['name'] as String?,
        );
        _cacheSession(current.uid, result);
        return result;
      }

      final userDoc = await _firestore.collection('users').doc(current.uid).get();

      if (userDoc.exists) {
        final data = userDoc.data() ?? {};
        final status = (data['status'] ?? 'active').toString();
        final banUntilRaw = data['banUntil'];
        DateTime? banUntil;
        if (banUntilRaw is Timestamp) {
          banUntil = banUntilRaw.toDate();
        }

        if (status == 'banned' &&
            banUntil != null &&
            DateTime.now().isAfter(banUntil)) {
          unawaited(
            _firestore.collection('users').doc(current.uid).update({
              'status': 'active',
              'banUntil': null,
            }).catchError((error) {
              developer.log(
                'Failed to auto-reactivate expired ban: $error',
                name: 'AuthController',
              );
            }),
          );
        } else if (status == 'banned' || status == 'blocked') {
          await signOut();
          return const SessionResult(role: SessionRole.guest);
        }
      }

      const result = SessionResult(role: SessionRole.user);
      _cacheSession(current.uid, result);
      return result;
    } catch (e) {
      // Failsafe for offline mode: keep already-authenticated users in user flow
      // instead of failing navigation with a blank transition.
      developer.log('resolveSession fallback to user due to error: $e', name: 'AuthController');
      const result = SessionResult(role: SessionRole.user);
      _cacheSession(current.uid, result);
      return result;
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      _invalidateAuthStreamCache();
      _invalidateSessionCache();
      await _firebaseAuth.signOut();
    } catch (e) {
      developer.log('Sign out error: $e', name: 'AuthController');
      throw Exception('Failed to sign out');
    }
  }

  // Update user profile
  Future<void> updateUserProfile({
    required String uid,
    String? username,
    String? firstName,
    String? lastName,
    String? avatarId,
    String? city,
  }) async {
    try {
      final updateData = <String, dynamic>{};
      if (username != null) updateData['username'] = username;
      if (firstName != null) updateData['firstName'] = firstName;
      if (lastName != null) updateData['lastName'] = lastName;
      if (avatarId != null) updateData['avatarId'] = avatarId;
      if (city != null) updateData['city'] = city;

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
      developer.log(
        'Send password reset email error: $e',
        name: 'AuthController',
      );
      throw Exception(
        'Impossible d\'envoyer l\'email. Vérifiez que votre adresse email est correcte.',
      );
    }
  }

  // Handle Firebase Auth exceptions
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    return Exception(switch (e.code) {
      'weak-password' =>
        'The password provided is too weak. Please use a stronger password.',
      'email-already-in-use' =>
        'This email is already registered. Please sign in or use a different email.',
      'invalid-email' =>
        'The email address is invalid. Please check and try again.',
      'user-disabled' => 'This user account has been disabled.',
      'user-not-found' => 'No account found with this email address.',
      'wrong-password' || 'invalid-credential' =>
        'The password is incorrect. Please try again.',
      'too-many-requests' => 'Too many login attempts. Please try again later.',
      _ => 'An authentication error occurred. Please try again.',
    });
  }

  Future<String?> _validateAndNormalizeUserAccess({
    required String uid,
    required bool enforceRestriction,
  }) async {
    final userDoc = await _firestore.collection('users').doc(uid).get();
    if (!userDoc.exists) {
      return null;
    }

    final data = userDoc.data() ?? <String, dynamic>{};
    final status = (data['status'] ?? 'active').toString();
    final banUntilValue = data['banUntil'];

    DateTime? banUntil;
    if (banUntilValue is Timestamp) {
      banUntil = banUntilValue.toDate();
    } else if (banUntilValue is String) {
      banUntil = DateTime.tryParse(banUntilValue);
    }

    if (status == 'banned' &&
        banUntil != null &&
        DateTime.now().isAfter(banUntil)) {
      await _firestore.collection('users').doc(uid).update({
        'status': 'active',
        'banUntil': null,
      });
      return null;
    }

    if (!enforceRestriction) {
      return null;
    }

    if (status == 'blocked') {
      return _blockedMessage;
    }

    if (status == 'banned') {
      if (banUntil == null) {
        return 'Your account is banned until further notice.';
      }
      return 'Your account is banned until ${_formatBanDate(banUntil)}';
    }

    return null;
  }

  String _formatBanDate(DateTime date) {
    final yyyy = date.year.toString().padLeft(4, '0');
    final mm = date.month.toString().padLeft(2, '0');
    final dd = date.day.toString().padLeft(2, '0');
    final hh = date.hour.toString().padLeft(2, '0');
    final min = date.minute.toString().padLeft(2, '0');
    return '$yyyy-$mm-$dd $hh:$min';
  }
}
