import 'package:flutter/foundation.dart';
import 'package:geolocator/geolocator.dart';

import '../models/station_model.dart';
import '../services/station_repository.dart';

class JourneyInputResolution {
  final Station? fromStation;
  final Station? toStation;
  final List<Station> fromSuggestions;
  final List<Station> toSuggestions;
  final String? errorMessage;

  const JourneyInputResolution({
    this.fromStation,
    this.toStation,
    this.fromSuggestions = const [],
    this.toSuggestions = const [],
    this.errorMessage,
  });

  bool get isReady => fromStation != null && toStation != null && errorMessage == null;

  /// Creates a copy of this resolution with the given fields replaced.
  /// 
  /// Use [clearError], [clearFromStation], or [clearToStation] to explicitly
  /// set those nullable fields to null, since null is a valid value for them.
  JourneyInputResolution copyWith({
    Station? fromStation,
    Station? toStation,
    List<Station>? fromSuggestions,
    List<Station>? toSuggestions,
    String? errorMessage,
    bool clearError = false,
    bool clearFromStation = false,
    bool clearToStation = false,
  }) {
    return JourneyInputResolution(
      fromStation: clearFromStation ? null : (fromStation ?? this.fromStation),
      toStation: clearToStation ? null : (toStation ?? this.toStation),
      fromSuggestions: fromSuggestions ?? this.fromSuggestions,
      toSuggestions: toSuggestions ?? this.toSuggestions,
      errorMessage: clearError ? null : (errorMessage ?? this.errorMessage),
    );
  }
}

class JourneyInputController {
  final StationRepository _stationRepository;

  JourneyInputController(this._stationRepository);

  Future<List<Station>> fetchAllStations({bool forceRefresh = false}) {
    return _stationRepository.getAllStations(forceRefresh: forceRefresh);
  }

  List<Station> suggestStationsLocally(String query, List<Station> allStations) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return [];
    
    final ranked = _stationRepository.rankStations(
      query: trimmed,
      stations: allStations,
      limit: 8,
    );
    return ranked.map((m) => m.station).toList();
  }

  Future<Station?> resolveStation(String query, List<Station> allStations) async {
    final trimmedQuery = query.trim();
    if (trimmedQuery.isEmpty) return null;

    // Try local suggestions first (fast path)
    final local = suggestStationsLocally(trimmedQuery, allStations);
    if (local.isNotEmpty) {
      // rankStations already scores exact matches highest via edit distance
      return local.first;
    }

    // Fall back to remote search with error handling
    try {
      final remote = await _stationRepository.searchStationsByName(trimmedQuery);
      return remote.isNotEmpty ? remote.first : null;
    } catch (e) {
      debugPrint('[JourneyInputController] Remote search failed for "$trimmedQuery": $e');
      return null;
    }
  }

  Future<List<StationDistance>> resolveNearestStations(Position position) {
    return _stationRepository.findNearestStations(
      latitude: position.latitude,
      longitude: position.longitude,
      limit: 3,
    );
  }

  Future<JourneyInputResolution> resolveSearch({
    required String departureText,
    required String arrivalText,
    required bool useCurrentLocation,
    required String unableResolveCurrentLocationMessage,
    required String noNearbyStationFromLocationMessage,
    required String Function(String query) stationNotFoundBuilder,
    required String Function(String query, String suggestions)
        stationNotFoundWithSuggestionsBuilder,
    Position? currentPosition,
    Station? selectedDeparture,
    Station? selectedArrival,
    required List<Station> allStations,
  }) async {
    final trimmedDeparture = departureText.trim();
    final trimmedArrival = arrivalText.trim();

    // Early return for completely empty state
    if (!useCurrentLocation && trimmedDeparture.isEmpty && trimmedArrival.isEmpty) {
      return const JourneyInputResolution();
    }

    Station? from = selectedDeparture;
    Station? to = selectedArrival;

    // Stale selection check that handles aliases
    // Note: Very short inputs (1-2 chars) may rarely invalidate a selection
    // due to substring matching, but this provides the best UX for common cases
    if (from != null && trimmedDeparture.isNotEmpty) {
      final normalizedName = StationRepository.normalizeStationText(from.name);
      final normalizedInput = StationRepository.normalizeStationText(trimmedDeparture);
      if (!normalizedName.contains(normalizedInput) &&
          !normalizedInput.contains(normalizedName)) {
        from = null;
      }
    }

    if (to != null && trimmedArrival.isNotEmpty) {
      final normalizedName = StationRepository.normalizeStationText(to.name);
      final normalizedInput = StationRepository.normalizeStationText(trimmedArrival);
      if (!normalizedName.contains(normalizedInput) &&
          !normalizedInput.contains(normalizedName)) {
        to = null;
      }
    }

    final fromSuggestions = suggestStationsLocally(trimmedDeparture, allStations);
    final toSuggestions = suggestStationsLocally(trimmedArrival, allStations);

    // Handle departure resolution
    if (useCurrentLocation) {
      if (currentPosition == null) {
        return JourneyInputResolution(
          fromSuggestions: fromSuggestions,
          toSuggestions: toSuggestions,
          errorMessage: unableResolveCurrentLocationMessage,
        );
      }
      
      final nearest = await resolveNearestStations(currentPosition);
      if (nearest.isEmpty) {
        return JourneyInputResolution(
          fromSuggestions: fromSuggestions,
          toSuggestions: toSuggestions,
          errorMessage: noNearbyStationFromLocationMessage,
        );
      }
      from = nearest.first.station;
      
      // GPS path: return early when arrival is empty (waiting for user input)
      if (trimmedArrival.isEmpty) {
        return JourneyInputResolution(
          fromStation: from,
          fromSuggestions: fromSuggestions,
          toSuggestions: toSuggestions,
        );
      }
    } else if (trimmedDeparture.isNotEmpty) {
      from ??= await resolveStation(trimmedDeparture, allStations);
    }

    // Handle arrival resolution
    if (trimmedArrival.isNotEmpty) {
      to ??= await resolveStation(trimmedArrival, allStations);
    }

    // Validate departure
    if (trimmedDeparture.isNotEmpty && from == null) {
      return JourneyInputResolution(
        fromSuggestions: fromSuggestions,
        toSuggestions: toSuggestions,
        errorMessage: _buildNotFoundMessage(
          query: trimmedDeparture,
          suggestions: fromSuggestions,
          stationNotFoundBuilder: stationNotFoundBuilder,
          stationNotFoundWithSuggestionsBuilder:
              stationNotFoundWithSuggestionsBuilder,
        ),
      );
    }

    // Validate arrival
    if (trimmedArrival.isNotEmpty && to == null) {
      return JourneyInputResolution(
        fromStation: from,
        fromSuggestions: fromSuggestions,
        toSuggestions: toSuggestions,
        errorMessage: _buildNotFoundMessage(
          query: trimmedArrival,
          suggestions: toSuggestions,
          stationNotFoundBuilder: stationNotFoundBuilder,
          stationNotFoundWithSuggestionsBuilder:
              stationNotFoundWithSuggestionsBuilder,
        ),
      );
    }

    // Same station validation
    if (from != null && to != null && from.id == to.id) {
      return JourneyInputResolution(
        fromStation: from,
        toStation: to,
        fromSuggestions: fromSuggestions,
        toSuggestions: toSuggestions,
        errorMessage: 'La station de départ et d\'arrivée sont identiques. Veuillez sélectionner deux stations différentes.',
      );
    }

    // Success case — may have to == null if arrival not yet typed (isReady = false)
    // This is intentional: the UI should wait silently for the user to complete both fields
    return JourneyInputResolution(
      fromStation: from,
      toStation: to,
      fromSuggestions: fromSuggestions,
      toSuggestions: toSuggestions,
    );
  }

  String _buildNotFoundMessage({
    required String query,
    required List<Station> suggestions,
    required String Function(String query) stationNotFoundBuilder,
    required String Function(String query, String suggestions)
        stationNotFoundWithSuggestionsBuilder,
  }) {
    if (suggestions.isEmpty) {
      return stationNotFoundBuilder(query);
    }
    final names = suggestions.take(3).map((s) => s.name).join(', ');
    return stationNotFoundWithSuggestionsBuilder(query, names);
  }
}