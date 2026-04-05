import 'dart:async';
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:tuni_transport/firebase_options.dart';

class AdminAuthResult {
  final bool isAuthenticated;
  final String? role;
  final String? name;
  final String? matricule;
  final String? errorMessage;

  const AdminAuthResult({
    required this.isAuthenticated,
    this.role,
    this.name,
    this.matricule,
    this.errorMessage,
  });
}

class AdminAuthController {
  AdminAuthController({FirebaseFirestore? firestore, FirebaseAuth? auth})
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;

  // ── Client-side brute-force protection ──────────────────────────────────────
  // Firebase enforces server-side rate limiting, but a local counter gives
  // immediate feedback and cuts unnecessary Auth round-trips while under attack.
  static const int _kLockoutThreshold = 5;
  int _failedAttempts = 0;
  DateTime? _lockedUntil;

  /// Exponential back-off: 30 s after the 5th failure, doubling every
  /// additional [_kLockoutThreshold] failures, capped at 15 minutes.
  Duration _nextLockoutDuration() {
    final tier = (_failedAttempts ~/ _kLockoutThreshold) - 1;
    var seconds = 30;
    for (var i = 0; i < tier.clamp(0, 5); i++) {
      seconds *= 2;
    }
    return Duration(seconds: seconds.clamp(30, 900));
  }

  void _recordFailure() {
    _failedAttempts++;
    if (_failedAttempts % _kLockoutThreshold == 0) {
      _lockedUntil = DateTime.now().add(_nextLockoutDuration());
    }
  }

  Future<AdminAuthResult> login({
    required String matricule,
    required String password,
  }) async {
    final sanitizedMatricule = matricule.trim();
    final sanitizedPassword = password.trim();

    if (sanitizedMatricule.isEmpty || sanitizedPassword.isEmpty) {
      return const AdminAuthResult(
        isAuthenticated: false,
        errorMessage: 'Matricule and password are required.',
      );
    }

    // Client-side lockout check — immediate rejection before any network call.
    if (_lockedUntil != null && DateTime.now().isBefore(_lockedUntil!)) {
      final remaining = _lockedUntil!.difference(DateTime.now());
      final secs = remaining.inSeconds + 1;
      return AdminAuthResult(
        isAuthenticated: false,
        errorMessage:
            'Too many failed attempts. Try again in $secs second${secs == 1 ? '' : 's'}.',
      );
    }

    try {
      // Derive the Firebase Auth email from the matricule so we can
      // authenticate BEFORE reading Firestore.  Admin accounts are
      // registered as {matricule}@admin.local by create_admin_accounts.js.
      final email = '${sanitizedMatricule.toLowerCase()}@admin.local';

      // Sign in first — no unauthenticated Firestore read required.
      final credential = await _auth.signInWithEmailAndPassword(
        email: email,
        password: sanitizedPassword,
      );

      final uid = credential.user?.uid;
      if (uid == null) {
        return const AdminAuthResult(
          isAuthenticated: false,
          errorMessage: 'Authentication failed: no user returned.',
        );
      }

      // Now authenticated — fetch the admin profile by uid.
      final adminDoc =
          await _firestore.collection('admins').doc(uid).get();

      if (!adminDoc.exists) {
        // Auth succeeded but no Firestore profile exists; sign out to keep
        // the session clean and surface a useful message.
        await _auth.signOut();
        return const AdminAuthResult(
          isAuthenticated: false,
          errorMessage:
              'Admin profile not found. Ensure the account was provisioned with create_admin_accounts.js.',
        );
      }

      // Successful login — reset the failure counter.
      _failedAttempts = 0;
      _lockedUntil = null;

      final adminData = adminDoc.data()!;
      return AdminAuthResult(
        isAuthenticated: true,
        role: adminData['role'] as String?,
        name: adminData['name'] as String?,
        matricule: (adminData['matricule'] ?? sanitizedMatricule).toString(),
      );
    } on FirebaseAuthException catch (e) {
      // Count credential errors toward the lockout threshold.
      // 'user-not-found' is treated identically to 'invalid-credential' so
      // that an attacker cannot enumerate valid matricules from the response.
      if (const {
        'user-not-found',
        'invalid-password',
        'wrong-password',
        'invalid-credential',
      }.contains(e.code)) {
        _recordFailure();
      }
      final message = switch (e.code) {
        'user-not-found' ||
        'invalid-password' ||
        'wrong-password' ||
        'invalid-credential' =>
          'Invalid matricule or password.',
        'too-many-requests' =>
          'Too many login attempts. Please try again later.',
        _ => e.message ?? 'Authentication error during admin login.',
      };
      return AdminAuthResult(isAuthenticated: false, errorMessage: message);
    } on FirebaseException catch (e) {
      return AdminAuthResult(
        isAuthenticated: false,
        errorMessage: e.message ?? 'Firestore error during admin login.',
      );
    } catch (_) {
      return const AdminAuthResult(
        isAuthenticated: false,
        errorMessage: 'Unexpected error during admin login.',
      );
    }
  }

  // Ensures any Firebase session is cleared before returning to login.
  Future<void> signOut() async {
    await _auth.signOut();
  }

  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    String? matricule,
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      throw const FormatException('No authenticated admin session found.');
    }

    final sanitizedCurrent = currentPassword;
    final sanitizedNew = newPassword;

    if (sanitizedCurrent.trim().isEmpty || sanitizedNew.trim().isEmpty) {
      throw const FormatException('Current password and new password are required.');
    }

    final email = user.email ??
        ((matricule != null && matricule.trim().isNotEmpty)
            ? '${matricule.trim().toLowerCase()}@admin.local'
            : null);

    if (email == null || email.isEmpty) {
      throw const FormatException('Unable to determine admin account email.');
    }

    try {
      final apiKey = DefaultFirebaseOptions.currentPlatform.apiKey;

      final signInResponse = await http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:signInWithPassword?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'email': email,
              'password': sanitizedCurrent,
              'returnSecureToken': true,
            }),
          )
          .timeout(const Duration(seconds: 10));

      final signInData = jsonDecode(signInResponse.body) as Map<String, dynamic>;

      if (signInResponse.statusCode != 200) {
        final errorCode =
            ((signInData['error'] as Map<String, dynamic>?)?['message'] ?? '')
                .toString();
        if (errorCode.contains('INVALID_PASSWORD') ||
            errorCode.contains('INVALID_LOGIN_CREDENTIALS') ||
            errorCode.contains('EMAIL_NOT_FOUND')) {
          throw Exception('Le mot de passe actuel est incorrect.');
        }
        if (errorCode.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
          throw Exception('Too many attempts. Please try again later.');
        }
        throw Exception('Authentication error while changing password.');
      }

      final localId = (signInData['localId'] ?? '').toString();
      if (localId.isEmpty || localId != user.uid) {
        throw Exception('Le mot de passe actuel est incorrect.');
      }

      final idToken = (signInData['idToken'] ?? '').toString();
      if (idToken.isEmpty) {
        throw Exception('Authentication error while changing password.');
      }

      final updateResponse = await http
          .post(
            Uri.parse(
              'https://identitytoolkit.googleapis.com/v1/accounts:update?key=$apiKey',
            ),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'idToken': idToken,
              'password': sanitizedNew,
              'returnSecureToken': false,
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (updateResponse.statusCode != 200) {
        final updateData = jsonDecode(updateResponse.body) as Map<String, dynamic>;
        final errorCode =
            ((updateData['error'] as Map<String, dynamic>?)?['message'] ?? '')
                .toString();
        if (errorCode.contains('WEAK_PASSWORD')) {
          throw Exception('New password is too weak.');
        }
        if (errorCode.contains('TOO_MANY_ATTEMPTS_TRY_LATER')) {
          throw Exception('Too many attempts. Please try again later.');
        }
        throw Exception('Unable to update password. Please try again.');
      }

      await user.reload();
    } on TimeoutException {
      throw Exception('Operation timeout. Please check your network and try again.');
    } on FirebaseAuthException catch (e) {
      final lowerMessage = (e.message ?? '').toLowerCase();
      final message = switch (e.code) {
        'wrong-password' ||
        'invalid-credential' ||
        'invalid-login-credentials' ||
        'user-mismatch' ||
        'user-not-found' =>
          'Le mot de passe actuel est incorrect.',
        'weak-password' => 'New password is too weak.',
        'network-request-failed' =>
          'Erreur reseau. Verifiez votre connexion Internet.',
        'requires-recent-login' =>
          'Please log in again before changing your password.',
        'too-many-requests' =>
          'Too many attempts. Please try again later.',
        _ => (lowerMessage.contains('credential') ||
                lowerMessage.contains('password') ||
                lowerMessage.contains('mot de passe'))
            ? 'Le mot de passe actuel est incorrect.'
            : (e.message ?? 'Authentication error while changing password.'),
      };
      throw Exception(message);
    }
  }
}
