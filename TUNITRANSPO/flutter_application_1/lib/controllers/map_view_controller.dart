import 'package:flutter/material.dart';
import '../models/station_model.dart';
import '../services/station_repository.dart';
import '../services/route_repository.dart';

class MapViewController extends ChangeNotifier {
  final StationRepository _stationRepository;
  final RouteRepository _routeRepository;

  List<Station> _stations = [];
  List<Station> get stations => _stations;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _error;
  String? get error => _error;

  Station? _selectedStation;
  Station? get selectedStation => _selectedStation;

  MapViewController({
    required StationRepository stationRepository,
    required RouteRepository routeRepository,
  })  : _stationRepository = stationRepository,
        _routeRepository = routeRepository;

  /// Helper to emit state changes
  void _emit() {
    notifyListeners();
  }

  /// Load stations for a route by station IDs with parallel loading
  Future<void> loadStationsByIds(List<String> stationIds) async {
    _isLoading = true;
    _error = null;
    _emit();

    try {
      // Load stations in parallel for better performance
      final results = await Future.wait(
        stationIds.map((id) => _stationRepository.getStationById(id)),
      );
      
      _stations = results.whereType<Station>().toList();
      _isLoading = false;
      _emit();
    } catch (e) {
      _error = 'Failed to load stations: ${_getUserFriendlyErrorMessage(e)}';
      _isLoading = false;
      _emit();
      debugPrint('[MapViewController] Error loading stations by IDs: $e');
    }
  }

  /// Load all stations in a city
  Future<void> loadStationsByCity(String cityId) async {
    if (cityId.trim().isEmpty) {
      _error = 'Invalid city ID';
      _emit();
      return;
    }

    _isLoading = true;
    _error = null;
    _emit();

    try {
      final allStations = await _stationRepository.getAllStations();
      _stations = allStations.where((station) => station.cityId == cityId).toList();
      _isLoading = false;
      _emit();
    } catch (e) {
      _error = 'Failed to load stations: ${_getUserFriendlyErrorMessage(e)}';
      _isLoading = false;
      _emit();
      debugPrint('[MapViewController] Error loading stations by city: $e');
    }
  }

  /// Select a station
  void selectStation(Station station) {
    if (_selectedStation == station) return; // Prevent unnecessary rebuilds
    _selectedStation = station;
    _emit();
  }

  /// Clear selection
  void clearSelection() {
    if (_selectedStation == null) return; // Prevent unnecessary rebuilds
    _selectedStation = null;
    _emit();
  }

  /// Clear all data
  void clear() {
    if (_stations.isEmpty && _selectedStation == null && _error == null) return;
    _stations = [];
    _selectedStation = null;
    _error = null;
    _isLoading = false;
    _emit();
  }

  /// Get user-friendly error message
  String _getUserFriendlyErrorMessage(dynamic error) {
    // Add specific error handling based on your error types
    if (error.toString().contains('network')) {
      return 'Network error. Please check your connection.';
    }
    if (error.toString().contains('permission')) {
      return 'Permission denied. Please try again later.';
    }
    return 'An unexpected error occurred. Please try again.';
  }
}