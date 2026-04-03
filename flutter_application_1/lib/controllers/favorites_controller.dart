import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;

import '../models/journey_model.dart';
import '../services/favorites_service.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController._();

  static final FavoritesController instance = FavoritesController._();

  final FavoritesService _favoritesService = FavoritesService();
  final firebase_auth.FirebaseAuth _auth = firebase_auth.FirebaseAuth.instance;
  final List<Journey> _favorites = [];
  bool _isLoading = false;
  String? _loadedForUid;

  List<Journey> get favorites => List<Journey>.unmodifiable(_favorites);
  bool get isLoading => _isLoading;

  Future<void> ensureFavoritesLoaded() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      if (_favorites.isNotEmpty || _loadedForUid != null) {
        _favorites.clear();
        _loadedForUid = null;
        notifyListeners();
      }
      return;
    }

    if (_isLoading) return;
    if (_loadedForUid == uid) return;

    await loadFavorites();
  }

  Future<void> loadFavorites() async {
    final uid = _auth.currentUser?.uid;
    if (uid == null) {
      _favorites.clear();
      _loadedForUid = null;
      notifyListeners();
      return;
    }

    _isLoading = true;
    notifyListeners();

    try {
      final items = await _favoritesService.getFavoriteJourneys();
      _favorites
        ..clear()
        ..addAll(items.map((journey) => journey.copyWith(isFavorite: true)));
      _loadedForUid = uid;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Journey journey) async {
    final alreadyFavorite = isFavorite(journey.id);
    final favoriteJourney = journey.copyWith(isFavorite: true);

    try {
      if (alreadyFavorite) {
        await _favoritesService.removeFavoriteJourney(journey.id);
        _favorites.removeWhere((item) => item.id == journey.id);
      } else {
        await _favoritesService.addFavoriteJourney(favoriteJourney);
        _favorites.insert(0, favoriteJourney);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('toggleFavorite failed for ${journey.id}: $e');
      rethrow;
    }
  }

  bool isFavorite(String journeyId) {
    return _favorites.any((journey) => journey.id == journeyId);
  }
}
