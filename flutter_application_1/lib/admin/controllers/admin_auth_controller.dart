import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

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

    try {
      // Query the admins collection to find admin by matricule.
      final querySnapshot = await _firestore
          .collection('admins')
          .where('matricule', isEqualTo: sanitizedMatricule)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const AdminAuthResult(
          isAuthenticated: false,
          errorMessage: 'Admin not found.',
        );
      }

      final adminData = querySnapshot.docs.first.data();

      // Get the email from admin document, or construct default email.
      final email =
          (adminData['email'] as String?) ?? '$sanitizedMatricule@admin.local';

      // Authenticate with Firebase Auth using email and password.
      await _auth.signInWithEmailAndPassword(
        email: email,
        password: sanitizedPassword,
      );

      return AdminAuthResult(
        isAuthenticated: true,
        role: adminData['role'] as String?,
        name: adminData['name'] as String?,
        matricule: (adminData['matricule'] ?? sanitizedMatricule).toString(),
      );
    } on FirebaseAuthException catch (e) {
      final message = switch (e.code) {
        'user-not-found' => 'Admin account not found in Firebase Auth.',
        'invalid-password' => 'Invalid email or password.',
        'invalid-credential' => 'Invalid email or password.',
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
}
