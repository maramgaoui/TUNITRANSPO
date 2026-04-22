import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../models/journey_model.dart';

class ActiveJourneyService extends ChangeNotifier {
  ActiveJourneyService._();

  static const String _activeJourneyKey = 'active_journey';
  static final ActiveJourneyService instance = ActiveJourneyService._();

  SharedPreferences? _prefs;
  Journey? _activeJourney;

  Journey? get activeJourney => _activeJourney;
  bool get hasActiveJourney => _activeJourney != null;

  Future<void> init() async {
    _prefs ??= await SharedPreferences.getInstance();
    final raw = _prefs!.getString(_activeJourneyKey);
    if (raw == null || raw.isEmpty) {
      _activeJourney = null;
      return;
    }

    try {
      final decoded = jsonDecode(raw) as Map<String, dynamic>;
      _activeJourney = Journey.fromJson(decoded);
    } catch (_) {
      _activeJourney = null;
      await _prefs!.remove(_activeJourneyKey);
    }
  }

  Future<void> setActiveJourney(Journey journey) async {
    _activeJourney = journey;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_activeJourneyKey, jsonEncode(journey.toJson()));
    notifyListeners();
  }

  Future<void> clearActiveJourney() async {
    _activeJourney = null;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_activeJourneyKey);
    notifyListeners();
  }
}
