import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/journey_model.dart';

class FavoritesService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;

  CollectionReference<Map<String, dynamic>> _favoritesRef(String uid) {
    return _firestore.collection('users').doc(uid).collection('favorites');
  }

  Future<void> addFavoriteJourney(Journey journey) async {
    final user = _auth.currentUser;
    if (user == null) return;

    // Store full journey payload so favorites can be shown after app restart.
    final payload = journey.copyWith(isFavorite: true).toJson();
    await _favoritesRef(user.uid).doc(journey.id).set(payload);
  }

  Future<void> removeFavoriteJourney(String journeyId) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _favoritesRef(user.uid).doc(journeyId).delete();
  }

  Future<List<Journey>> getFavoriteJourneys() async {
    final user = _auth.currentUser;
    if (user == null) return [];

    final snapshot = await _favoritesRef(user.uid).get();

    return snapshot.docs.map((doc) {
      final data = doc.data();
      return Journey.fromJson({
        ...data,
        'id': doc.id,
        'isFavorite': true,
      });
    }).toList();
  }
}
