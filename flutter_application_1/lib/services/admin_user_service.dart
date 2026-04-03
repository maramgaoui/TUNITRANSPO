import 'package:cloud_firestore/cloud_firestore.dart';

class AdminUserService {
  AdminUserService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;
  static const String _usersCollection = 'users';

  Future<void> banUser(String userId, {required int days}) async {
    final until = DateTime.now().add(Duration(days: days));
    await _firestore.collection(_usersCollection).doc(userId).update({
      'status': 'banned',
      'banUntil': Timestamp.fromDate(until),
    });
  }

  Future<void> blockUser(String userId) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'status': 'blocked',
      'banUntil': null,
    });
  }

  Future<void> unblockUser(String userId) async {
    await _firestore.collection(_usersCollection).doc(userId).update({
      'status': 'active',
      'banUntil': null,
    });
  }
}
