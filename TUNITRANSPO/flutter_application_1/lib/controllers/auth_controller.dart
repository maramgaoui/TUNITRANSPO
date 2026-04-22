import 'dart:async';
import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart' show visibleForTesting;
import 'package:google_sign_in/google_sign_in.dart';
import 'package:shared_preferences/shared_preferences.dart';
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

  /// The shared app-wide instance.  Defaults to a production controller.
  /// Call [AuthController.resetInstance] in tests to inject a fake.
  static AuthController instance = AuthController();

  /// Replace the global instance (for tests only).
  @visibleForTesting
  static void resetInstance(AuthController controller) {
    instance = controller;
  }
  static const Duration _authStreamTtl = Duration(seconds: 60);
  static const Duration _sessionTtl = Duration(minutes: 5);
  static const String _sessionCachePrefix = 'auth.session.';

  final firebase_auth.FirebaseAuth _firebaseAuth;
  final FirebaseFirestore _firestore;
  GoogleSignIn? _googleSignIn;
  SessionResult? _cachedSession;
  DateTime? _sessionCachedAt;
  String? _cachedSessionUid;
  User? _cachedAuthStreamUser;
  DateTime? _authStreamCachedAt;
  String? _cachedAuthStreamUid;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>?
      _userStatusSubscription;
  String? _userStatusListenerUid;
  String? _lastObservedUserStatus;

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

  void _invalidateSessionCache({String? uid, bool clearPersistent = true}) {
    final targetUid = uid ?? _cachedSessionUid;
    _cachedSession = null;
    _sessionCachedAt = null;
    _cachedSessionUid = null;
    if (clearPersistent && targetUid != null && targetUid.isNotEmpty) {
      unawaited(_clearPersistedSession(targetUid));
    }
  }

  void _cacheSession(
    String uid,
    SessionResult session, {
    String accountStatus = 'active',
  }) {
    _cachedSession = session;
    _sessionCachedAt = DateTime.now();
    _cachedSessionUid = uid;
    unawaited(
      _persistSession(
        uid,
        session,
        accountStatus: accountStatus,
      ),
    );
  }

  String _sessionCacheKey(String uid) => '$_sessionCachePrefix$uid';

  Future<void> _persistSession(
    String uid,
    SessionResult session, {
    required String accountStatus,
  }) async {
    if (uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      final payload = <String, dynamic>{
        'role': session.role.name,
        'adminRole': session.adminRole,
        'adminMatricule': session.adminMatricule,
        'adminName': session.adminName,
        'accountStatus': accountStatus,
        'cachedAt': DateTime.now().toIso8601String(),
      };
      await prefs.setString(_sessionCacheKey(uid), jsonEncode(payload));
    } catch (e) {
      developer.log(
        'Failed to persist session cache: $e',
        name: 'AuthController',
      );
    }
  }

  Future<void> _clearPersistedSession(String uid) async {
    if (uid.isEmpty) return;

    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_sessionCacheKey(uid));
    } catch (e) {
      developer.log(
        'Failed to clear persisted session cache: $e',
        name: 'AuthController',
      );
    }
  }

  Future<SessionResult?> _loadPersistedSession(String uid) async {
    if (uid.isEmpty) return null;

    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString(_sessionCacheKey(uid));
      if (raw == null || raw.isEmpty) return null;

      final decoded = jsonDecode(raw);
      if (decoded is! Map<String, dynamic>) {
        return null;
      }

      final roleName = (decoded['role'] ?? '').toString();
      final role = SessionRole.values.firstWhere(
        (candidate) => candidate.name == roleName,
        orElse: () => SessionRole.guest,
      );

      return SessionResult(
        role: role,
        adminRole: decoded['adminRole'] as String?,
        adminMatricule: decoded['adminMatricule'] as String?,
        adminName: decoded['adminName'] as String?,
      );
    } catch (e) {
      developer.log(
        'Failed to load persisted session cache: $e',
        name: 'AuthController',
      );
      return null;
    }
  }

  bool _isDefinitiveSessionFailure(Object error) {
    if (error is FirebaseException) {
      return error.code == 'permission-denied' ||
          error.code == 'unauthenticated';
    }

    if (error is firebase_auth.FirebaseAuthException) {
      return error.code == 'user-disabled' ||
          error.code == 'invalid-user-token' ||
          error.code == 'user-token-expired';
    }

    return false;
  }

  Future<void> _cancelUserStatusListener() async {
    await _userStatusSubscription?.cancel();
    _userStatusSubscription = null;
    _userStatusListenerUid = null;
    _lastObservedUserStatus = null;
  }

  Future<void> _setUserStatusListener(String uid) async {
    if (_userStatusSubscription != null && _userStatusListenerUid == uid) {
      return;
    }

    await _cancelUserStatusListener();

    _userStatusListenerUid = uid;
    _userStatusSubscription = _firestore
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen(
          (snapshot) {
            final data = snapshot.data();
            final currentStatus = (data?['status'] ?? 'active').toString();

            if (_lastObservedUserStatus == null) {
              _lastObservedUserStatus = currentStatus;
              return;
            }

            if (_lastObservedUserStatus != currentStatus) {
              _lastObservedUserStatus = currentStatus;
              _invalidateSessionCache(uid: uid);
            }
          },
          onError: (error) {
            developer.log(
              'User status listener error: $error',
              name: 'AuthController',
            );
          },
        );
  }

  Future<void> _safeSignOut({bool clearSessionCache = true}) async {
    final currentUid = _firebaseAuth.currentUser?.uid;

    _invalidateAuthStreamCache();
    _invalidateSessionCache(uid: currentUid, clearPersistent: clearSessionCache);
    await _cancelUserStatusListener();

    try {
      await _firebaseAuth.signOut();
    } catch (e) {
      developer.log('Safe sign out error: $e', name: 'AuthController');
    }
  }

  // Get current user stream
  Stream<User?> get authStateChanges {
    return _firebaseAuth.authStateChanges().asyncMap((
      firebase_auth.User? user,
    ) async {
      if (user == null) {
        _invalidateAuthStreamCache();
        await _cancelUserStatusListener();
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
          await _safeSignOut();
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
        await _setUserStatusListener(user.uid);
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
        throw Exception('auth.error.account_creation_failed');
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
        _invalidateSessionCache(uid: firebaseUser.uid);
        return User.fromMap(userDoc.data() ?? {});
      } else {
        // Return basic user if not in Firestore
        _invalidateSessionCache(uid: firebaseUser.uid);
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

      // ── Pre-auth block check ──────────────────────────────────
      // Query Firestore BEFORE creating/signing into Firebase Auth
      // so a blocked user never obtains a valid auth session.
      final googleEmail = googleUser.email;
      if (googleEmail.isNotEmpty) {
        final existingByEmail = await _firestore
            .collection('users')
            .where('email', isEqualTo: googleEmail)
            .limit(1)
            .get();

        if (existingByEmail.docs.isNotEmpty) {
          final existingData = existingByEmail.docs.first.data();
          final status = (existingData['status'] ?? 'active').toString();
          if (status == 'blocked') {
            throw Exception(_blockedMessage);
          }
          if (status == 'banned') {
            final banUntilRaw = existingData['banUntil'];
            DateTime? banUntil;
            if (banUntilRaw is Timestamp) {
              banUntil = banUntilRaw.toDate();
            }
            if (banUntil == null || !DateTime.now().isAfter(banUntil)) {
              throw Exception(
                banUntil == null
                    ? 'Your account is banned until further notice.'
                    : 'Your account is banned until ${_formatBanDate(banUntil)}',
              );
            }
          }
        }
      }

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
        _invalidateSessionCache(uid: firebaseUser.uid);
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

        _invalidateSessionCache(uid: firebaseUser.uid);
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

      // 1) Primary lookup: by document ID (uid) — single read, no index needed.
      //    This is the authoritative key that matches the isAdmin() Firestore
      //    rule: exists(/admins/$(request.auth.uid)).
      final adminDoc = await _firestore
          .collection('admins')
          .doc(current.uid)
          .get();

      Map<String, dynamic>? adminData;
      if (adminDoc.exists) {
        adminData = adminDoc.data();
      } else if (email.isNotEmpty) {
        // 2) Fallback lookup by email (covers admins not yet keyed by uid).
        final adminSnapshot = await _firestore
            .collection('admins')
            .where('email', isEqualTo: email)
            .limit(1)
            .get();
        if (adminSnapshot.docs.isNotEmpty) {
          adminData = adminSnapshot.docs.first.data();
          // Migrate: write a uid-keyed mirror document so subsequent lookups
          // and the isAdmin() Firestore rule both work.
          unawaited(
            _firestore.collection('admins').doc(current.uid).set(
              {...adminData, 'uid': current.uid},
              SetOptions(merge: true),
            ).catchError((e) {
              developer.log(
                'Failed to migrate admin doc to uid key: $e',
                name: 'AuthController',
              );
            }),
          );
        }
      }

      if (adminData != null) {
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
          const bannedResult = SessionResult(role: SessionRole.guest);
          _cacheSession(current.uid, bannedResult, accountStatus: status);
          await _safeSignOut(clearSessionCache: false);
          return bannedResult;
        }
      }

      const result = SessionResult(role: SessionRole.user);
      _cacheSession(current.uid, result);
      return result;
    } catch (e) {
      if (_isDefinitiveSessionFailure(e)) {
        developer.log(
          'resolveSession forcing sign-out after definitive failure: $e',
          name: 'AuthController',
        );
        await _safeSignOut();
        return const SessionResult(role: SessionRole.guest);
      }

      final persisted = await _loadPersistedSession(current.uid);
      if (persisted != null) {
        _cacheSession(current.uid, persisted);
        developer.log(
          'resolveSession restored cached role after transient failure: $e',
          name: 'AuthController',
        );
        return persisted;
      }

      developer.log(
        'resolveSession transient failure with no cache, defaulting to guest: $e',
        name: 'AuthController',
      );
      return const SessionResult(role: SessionRole.guest);
    }
  }

  // Sign out
  Future<void> signOut() async {
    try {
      await _safeSignOut();
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
      // Delete Firebase Auth user
      await _firebaseAuth.currentUser?.delete();

      // Delete user data from Firestore only after auth deletion succeeds.
      await _firestore.collection('users').doc(uid).delete();
    } on firebase_auth.FirebaseAuthException catch (e) {
      if (e.code == 'requires-recent-login') {
        rethrow;
      }
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
        'auth.error.password_reset_failed',
      );
    }
  }

  // Handle Firebase Auth exceptions — returns l10n-friendly error keys.
  Exception _handleAuthException(firebase_auth.FirebaseAuthException e) {
    return Exception(switch (e.code) {
      'weak-password' => 'auth.error.weak_password',
      'email-already-in-use' => 'auth.error.email_already_in_use',
      'invalid-email' => 'auth.error.invalid_email',
      'user-disabled' => 'auth.error.user_disabled',
      'user-not-found' => 'auth.error.user_not_found',
      'wrong-password' || 'invalid-credential' => 'auth.error.wrong_password',
      'too-many-requests' => 'auth.error.too_many_requests',
      _ => 'auth.error.generic',
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
