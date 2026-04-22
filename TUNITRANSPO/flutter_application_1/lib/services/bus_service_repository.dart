import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/bus_service_model.dart';
import '../utils/text_normalizer.dart';

class BusServiceRepository {
  final FirebaseFirestore _firestore;

  // List of all TRANSTU hub station IDs
  static const Set<String> _transtuHubIds = {
    'transtu_hub_10_decembre',
    'transtu_hub_barcelone',
    'transtu_hub_ariana',
    'transtu_hub_bab_alioua',
    'transtu_hub_charguia',
    'transtu_hub_khaireddine',
    'transtu_hub_tunis_marine',
    'transtu_hub_intilaka',
    'transtu_hub_morneg',
    'transtu_hub_tbourba',
    'transtu_hub_slimlen_kahia',
    'transtu_hub_bellevie',
    'transtu_hub_carthage',
    'transtu_hub_jardin_thameur',
    'transtu_hub_montazah',
  };

  BusServiceRepository([FirebaseFirestore? firestore])
      : _firestore = firestore ?? FirebaseFirestore.instance;

  /// Get all bus services departing from a given hub station.
  Future<List<BusService>> getServicesForHub(String hubStationId) async {
    final snap = await _firestore
        .collection('bus_services')
        .where('hubStationId', isEqualTo: hubStationId)
        .where('operatingDays', arrayContains: DateTime.now().weekday % 7)
        .get();
    return snap.docs.map(BusService.fromFirestore).toList()
      ..sort((a, b) => (a.firstDepartureFromHub ?? '99:99')
          .compareTo(b.firstDepartureFromHub ?? '99:99'));
  }

  /// Get bus services from a hub that match a specific destination query.
  Future<List<BusService>> getServicesForHubFiltered({
    required String hubStationId,
    String? destinationQuery,
  }) async {
    final all = await getServicesForHub(hubStationId);
    if (destinationQuery == null || destinationQuery.trim().isEmpty) {
      return all;
    }

    final filtered = _filterByDestination(all, destinationQuery.trim());
    return filtered.isEmpty ? all : filtered;
  }

  /// Search bus lines by line number or direction.
  Future<List<BusService>> searchLines(String query) async {
    final snap = await _firestore.collection('bus_services').get();
    final q = query.toLowerCase();
    return snap.docs
        .map(BusService.fromFirestore)
        .where((s) =>
            s.lineNumber.toLowerCase().contains(q) ||
            s.directionAr.contains(query) ||
            (s.destinationNameFr?.toLowerCase().contains(q) ?? false))
        .toList();
  }

  /// Finds bus lines between origin and destination with intelligent matching.
  Future<List<BusService>> findLinesBetween({
    required String originStationId,
    required String targetDestination,
  }) async {
    return getServicesForHubFiltered(
      hubStationId: originStationId,
      destinationQuery: targetDestination,
    );
  }

  /// Filters a list of [BusService] by matching [query] against
  /// the service's Arabic direction or French destination name.
  List<BusService> _filterByDestination(
    List<BusService> services,
    String query,
  ) {
    if (query.trim().isEmpty) return services;

    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Filtering ${services.length} services for: "$query"');
    }

    final threshold = query.length <= 10 ? 0.50 : 0.65;

    final result = TextNormalizer.filterItems<BusService>(
      services,
      query,
      extractors: [
        (s) => s.directionAr,
        (s) => s.destinationNameFr ?? '',
      ],
      threshold: threshold,
    );

    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Filtered to ${result.length} services: ${result.map((s) => '${s.lineNumber}→${s.destinationNameFr}').join(', ')}');
    }

    return result;
  }

  /// Check if a station ID is a TRANSTU hub
  bool isTranstuHub(String stationId) {
    return _transtuHubIds.contains(stationId);
  }

  /// Get the hub station ID from a destination station ID
  /// This maps destination stations to their hub
  String? getHubForDestination(String destinationId) {
    // Map of destination station IDs to their hub
    const destinationToHub = {
      // 10 December hub destinations
      'transtu_dest_sidi_sofiane': 'transtu_hub_10_decembre',
      'transtu_dest_cité_mellaha': 'transtu_hub_10_decembre',
      'transtu_dest_ghazala': 'transtu_hub_10_decembre',
      'transtu_dest_raoued': 'transtu_hub_10_decembre',
      'transtu_dest_kalaat_andalous': 'transtu_hub_10_decembre',
      'transtu_dest_sidi_omar': 'transtu_hub_10_decembre',
      'transtu_dest_el_brarjia': 'transtu_hub_10_decembre',
      'transtu_dest_ariana_brarjia': 'transtu_hub_10_decembre',
      'transtu_dest_la_goulette': 'transtu_hub_10_decembre',
      'transtu_dest_cité_bakri': 'transtu_hub_10_decembre',
      'transtu_dest_nour_jafar': 'transtu_hub_10_decembre',
      
      // Barcelone hub destinations
      'transtu_dest_medina_jdida': 'transtu_hub_barcelone',
      'transtu_dest_hay_thameur': 'transtu_hub_barcelone',
      'transtu_dest_mornag': 'transtu_hub_barcelone',
      'transtu_dest_ben_arous': 'transtu_hub_barcelone',
      'transtu_dest_ibn_sina': 'transtu_hub_barcelone',
      'transtu_dest_boumhal': 'transtu_hub_barcelone',
      
      // Ariana hub destinations
      'transtu_dest_manji_salim': 'transtu_hub_ariana',
      'transtu_dest_sidi_salah': 'transtu_hub_ariana',
      'transtu_dest_menzah9': 'transtu_hub_ariana',
      'transtu_dest_manouba': 'transtu_hub_ariana',
    };
    
    return destinationToHub[destinationId];
  }

  /// Finds bus services that connect the origin station to the destination station.
  ///
  /// FIXED: Now properly handles:
  /// - Hub to destination (e.g., 10 December → Sidi Sofiane)
  /// - Destination to hub (reverse direction)
  /// - Hub to hub (direct connection)
  Future<List<BusService>> findServicesConnectingStations({
    required String fromStationId,
    required String toStationId,
  }) async {
    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Finding services from $fromStationId to $toStationId');
    }

    final fromIsHub = isTranstuHub(fromStationId);
    final toIsHub = isTranstuHub(toStationId);

    // Case 1: Hub to Destination (e.g., transtu_hub_10_decembre → transtu_dest_sidi_sofiane)
    if (fromIsHub && !toIsHub) {
      return _findServicesFromHubToDestination(fromStationId, toStationId);
    }

    // Case 2: Destination to Hub (reverse direction - user wants to go from destination to hub)
    if (!fromIsHub && toIsHub) {
      return _findServicesFromDestinationToHub(fromStationId, toStationId);
    }

    // Case 3: Hub to Hub (direct connection between two hubs)
    if (fromIsHub && toIsHub) {
      return _findDirectHubServices(fromStationId, toStationId);
    }

    // Case 4: Destination to Destination - need to find a hub that serves both
    if (!fromIsHub && !toIsHub) {
      return _findServicesViaTransfer(fromStationId, toStationId);
    }

    if (kDebugMode) {
      debugPrint('[BusServiceRepo] No connection pattern matched for $fromStationId → $toStationId');
    }

    return [];
  }

  /// Find services from a hub to a specific destination station
  Future<List<BusService>> _findServicesFromHubToDestination(
    String hubId,
    String destinationId,
  ) async {
    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Looking for hub→destination: $hubId → $destinationId');
    }

    // First, get all services from this hub
    final allServices = await getServicesForHub(hubId);
    
    // Filter by destination - match using directionAr or destinationNameFr
    final destinationName = _getDestinationName(destinationId);
    
    if (destinationName.isEmpty) {
      if (kDebugMode) {
        debugPrint('[BusServiceRepo] Unknown destination ID: $destinationId');
      }
      return [];
    }
    
    final matchedServices = allServices.where((service) {
      final directionMatches = service.directionAr.contains(destinationName) ||
          service.directionAr.contains(destinationName.replaceAll('_', ' '));
      final nameMatches = service.destinationNameFr?.toLowerCase().contains(
            destinationName.toLowerCase(),
          ) ?? false;
      
      return directionMatches || nameMatches;
    }).toList();
    
    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Found ${matchedServices.length} services from hub to destination');
      for (final service in matchedServices) {
        debugPrint('  - Line ${service.lineNumber}: ${service.destinationNameFr}');
      }
    }
    
    return matchedServices;
  }

  /// Find services from a destination to a hub (reverse direction)
  Future<List<BusService>> _findServicesFromDestinationToHub(
    String destinationId,
    String hubId,
  ) async {
    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Looking for destination→hub: $destinationId → $hubId');
    }
    
    // For reverse direction, we need the hub that serves this destination
    final actualHubId = getHubForDestination(destinationId) ?? hubId;
    
    // Get all services from that hub
    final allServices = await getServicesForHub(actualHubId);
    
    final destinationName = _getDestinationName(destinationId);
    
    final matchedServices = allServices.where((service) {
      final directionMatches = service.directionAr.contains(destinationName) ||
          service.directionAr.contains(destinationName.replaceAll('_', ' '));
      final nameMatches = service.destinationNameFr?.toLowerCase().contains(
            destinationName.toLowerCase(),
          ) ?? false;
      
      return directionMatches || nameMatches;
    }).toList();
    
    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Found ${matchedServices.length} services from destination to hub');
    }
    
    return matchedServices;
  }

  /// Find direct services between two hubs
  Future<List<BusService>> _findDirectHubServices(
    String hub1Id,
    String hub2Id,
  ) async {
    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Looking for hub→hub: $hub1Id → $hub2Id');
    }
    
    // Get services from first hub
    final services = await getServicesForHub(hub1Id);
    
    // Check if any service's destination matches hub2
    final hub2Name = hub2Id.replaceAll('transtu_hub_', '').replaceAll('_', ' ');
    
    final matchedServices = services.where((service) {
      return service.destinationNameFr?.toLowerCase().contains(hub2Name) ?? false;
    }).toList();
    
    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Found ${matchedServices.length} direct hub-to-hub services');
    }
    
    return matchedServices;
  }

  /// Find services that connect two destinations via a hub
  Future<List<BusService>> _findServicesViaTransfer(
    String fromDestinationId,
    String toDestinationId,
  ) async {
    if (kDebugMode) {
      debugPrint('[BusServiceRepo] Looking for destination→destination via transfer: $fromDestinationId → $toDestinationId');
    }
    
    // Find hub that serves the from destination
    final fromHub = getHubForDestination(fromDestinationId);
    if (fromHub == null) return [];
    
    // Find hub that serves the to destination
    final toHub = getHubForDestination(toDestinationId);
    if (toHub == null) return [];
    
    if (fromHub == toHub) {
      // Same hub serves both destinations
      return _findServicesFromHubToDestination(fromHub, toDestinationId);
    }
    
    // Different hubs - need to find connection between hubs
    return _findDirectHubServices(fromHub, toHub);
  }

  /// Helper to get readable destination name from ID
  String _getDestinationName(String destinationId) {
    // Extract name from destination ID
    if (destinationId.startsWith('transtu_dest_')) {
      return destinationId
          .replaceAll('transtu_dest_', '')
          .replaceAll('_', ' ')
          .toLowerCase();
    }
    return destinationId.toLowerCase();
  }

  /// Get all available destinations from a hub
  Future<List<Map<String, String>>> getDestinationsFromHub(String hubId) async {
    final services = await getServicesForHub(hubId);
    final destinations = <Map<String, String>>[];
    final seen = <String>{};
    
    for (final service in services) {
      final destName = service.destinationNameFr ?? service.directionAr;
      if (destName.isNotEmpty && !seen.contains(destName)) {
        seen.add(destName);
        destinations.add({
          'name': destName,
          'lineNumber': service.lineNumber,
          'directionAr': service.directionAr,
        });
      }
    }
    
    return destinations;
  }

  /// Validate that a hub has services configured
  Future<bool> validateHubServices(String hubId) async {
    final services = await getServicesForHub(hubId);
    if (services.isEmpty) {
      if (kDebugMode) {
        debugPrint('[BusServiceRepo] ⚠️ No services found for hub: $hubId');
      }
      return false;
    }
    
    if (kDebugMode) {
      debugPrint('[BusServiceRepo] ✅ Hub $hubId has ${services.length} services');
      for (final service in services) {
        debugPrint('  - Line ${service.lineNumber}: ${service.destinationNameFr}');
      }
    }
    
    return true;
  }
}