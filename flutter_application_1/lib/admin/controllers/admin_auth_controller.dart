import 'package:cloud_firestore/cloud_firestore.dart';

class AdminAuthResult {
  final bool isAuthenticated;
  final String? role;
  final String? errorMessage;

  const AdminAuthResult({
    required this.isAuthenticated,
    this.role,
    this.errorMessage,
  });
}

class AdminAuthController {
  AdminAuthController({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

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
      // Query the admins collection with both credentials.
      final querySnapshot = await _firestore
          .collection('admins')
          .where('matricule', isEqualTo: sanitizedMatricule)
          .where('password', isEqualTo: sanitizedPassword)
          .limit(1)
          .get();

      if (querySnapshot.docs.isEmpty) {
        return const AdminAuthResult(
          isAuthenticated: false,
          errorMessage: 'Invalid matricule or password.',
        );
      }

      final adminData = querySnapshot.docs.first.data();
      return AdminAuthResult(
        isAuthenticated: true,
        role: adminData['role'] as String?,
      );
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
}
