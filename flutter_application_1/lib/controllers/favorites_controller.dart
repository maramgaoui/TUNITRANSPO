import 'package:flutter/foundation.dart';

import '../models/journey_model.dart';
import '../services/favorites_service.dart';

class FavoritesController extends ChangeNotifier {
  FavoritesController._();

  static final FavoritesController instance = FavoritesController._();

  final FavoritesService _favoritesService = FavoritesService();
  final List<Journey> _favorites = [];
  bool _isLoading = false;

  List<Journey> get favorites => List<Journey>.unmodifiable(_favorites);
  bool get isLoading => _isLoading;

  Future<void> loadFavorites() async {
    _isLoading = true;
    notifyListeners();

    try {
      final items = await _favoritesService.getFavoriteJourneys();
      _favorites
        ..clear()
        ..addAll(items.map((journey) => journey.copyWith(isFavorite: true)));
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> toggleFavorite(Journey journey) async {
    if (isFavorite(journey.id)) {
      await _favoritesService.removeFavoriteJourney(journey.id);
      _favorites.removeWhere((item) => item.id == journey.id);
    } else {
      final favoriteJourney = journey.copyWith(isFavorite: true);
      await _favoritesService.addFavoriteJourney(favoriteJourney);
      _favorites.insert(0, favoriteJourney);
    }

    notifyListeners();
  }

  bool isFavorite(String journeyId) {
    return _favorites.any((journey) => journey.id == journeyId);
  }
}
