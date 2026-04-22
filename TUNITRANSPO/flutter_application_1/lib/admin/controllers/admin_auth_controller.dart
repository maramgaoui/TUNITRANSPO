import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
  AdminAuthController({
    FirebaseFirestore? firestore,
    FirebaseAuth? auth,
    SharedPreferences? sharedPreferences,
  })
    : _firestore = firestore ?? FirebaseFirestore.instance,
      _auth = auth ?? FirebaseAuth.instance,
      _sharedPreferences = sharedPreferences;

  final FirebaseFirestore _firestore;
  final FirebaseAuth _auth;
  final SharedPreferences? _sharedPreferences;

  // ── Client-side brute-force protection ──────────────────────────────────────
  // Firebase enforces server-side rate limiting, but a local counter gives
  // immediate feedback and cuts unnecessary Auth round-trips while under attack.
  static const int _kLockoutThreshold = 5;
  static const String _failedAttemptsKey = 'admin_auth.failed_attempts';
  static const String _lockedUntilEpochKey = 'admin_auth.locked_until_epoch';
  int _failedAttempts = 0;
  DateTime? _lockedUntil;
  bool _lockoutStateLoaded = false;

  Future<SharedPreferences> _prefs() async {
    return _sharedPreferences ?? await SharedPreferences.getInstance();
  }

  Future<void> _restoreLockoutStateIfNeeded() async {
    if (_lockoutStateLoaded) {
      return;
    }

    final prefs = await _prefs();
    _failedAttempts = prefs.getInt(_failedAttemptsKey) ?? 0;
    final lockedUntilEpoch = prefs.getInt(_lockedUntilEpochKey);
    _lockedUntil = lockedUntilEpoch == null
        ? null
        : DateTime.fromMillisecondsSinceEpoch(lockedUntilEpoch);
    _lockoutStateLoaded = true;
  }

  Future<void> _persistLockoutState() async {
    final prefs = await _prefs();
    await prefs.setInt(_failedAttemptsKey, _failedAttempts);
    final lockedUntil = _lockedUntil;
    if (lockedUntil == null) {
      await prefs.remove(_lockedUntilEpochKey);
    } else {
      await prefs.setInt(
        _lockedUntilEpochKey,
        lockedUntil.millisecondsSinceEpoch,
      );
    }
  }

  Future<void> _clearLockoutState() async {
    _failedAttempts = 0;
    _lockedUntil = null;
    await _persistLockoutState();
  }

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

  Future<void> _recordFailure() async {
    _failedAttempts++;
    if (_failedAttempts % _kLockoutThreshold == 0) {
      _lockedUntil = DateTime.now().add(_nextLockoutDuration());
    }
    await _persistLockoutState();
  }

  Future<AdminAuthResult> login({
    required String matricule,
    required String password,
  }) async {
    await _restoreLockoutStateIfNeeded();

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
      await _clearLockoutState();

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
        await _recordFailure();
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
      final credential = EmailAuthProvider.credential(
        email: email,
        password: sanitizedCurrent,
      );

      await user
          .reauthenticateWithCredential(credential)
          .timeout(const Duration(seconds: 10));

      await user
          .updatePassword(sanitizedNew)
          .timeout(const Duration(seconds: 10));

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
