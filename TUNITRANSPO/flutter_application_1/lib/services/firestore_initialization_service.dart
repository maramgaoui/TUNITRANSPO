import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';

/// Service to initialize and seed Firestore with TRANSTU data
class FirestoreInitializationService {
  static final FirestoreInitializationService _instance =
      FirestoreInitializationService._internal();

  final FirebaseFirestore _firestore;
  bool _isInitialized = false;

  factory FirestoreInitializationService({FirebaseFirestore? firestore}) {
    return _instance;
  }

  FirestoreInitializationService._internal()
      : _firestore = FirebaseFirestore.instance;

  /// Check if Firestore has been initialized with data
  Future<bool> get isInitialized async {
    if (_isInitialized) return true;
    
    try {
      final stationCount = await _firestore.collection('stations').count().get();
      _isInitialized = stationCount.count! > 0;
      return _isInitialized;
    } catch (e) {
      debugPrint('Error checking initialization: $e');
      return false;
    }
  }

  /// Initialize Firestore with TRANSTU data
  Future<void> initialize() async {
    if (_isInitialized) {
      debugPrint('[FirestoreInit] Already initialized, skipping.');
      return;
    }

    try {
      debugPrint('[FirestoreInit] Starting Firestore initialization...');
      await _seedTranstuData();
      _isInitialized = true;
      debugPrint('[FirestoreInit] Initialization complete!');
    } catch (e) {
      debugPrint('[FirestoreInit] Error during initialization: $e');
      rethrow;
    }
  }

  Future<void> _seedTranstuData() async {
    // Add TRANSTU hub stations
    final hubs = _getHubStations();
    final destinations = _getDestinationStations();
    
    debugPrint('[FirestoreInit] Adding ${hubs.length} hub stations...');
    for (final entry in hubs.entries) {
      await _firestore.collection('stations').doc(entry.key).set(entry.value);
    }

    debugPrint('[FirestoreInit] Adding ${destinations.length} destination stations...');
    for (final entry in destinations.entries) {
      await _firestore.collection('stations').doc(entry.key).set(entry.value);
    }

    // Add bus services and routes
    final routes = _getTranstuRoutes();
    debugPrint('[FirestoreInit] Adding ${routes.length} bus routes...');
    
    for (final entry in routes.entries) {
      final lineNumber = entry.key;
      final routeData = entry.value;
      
      final serviceDocId = 'transtu_line_$lineNumber';
      await _firestore
          .collection('bus_services')
          .doc(serviceDocId)
          .set(routeData['service']);
      
      // Add route stops
      for (int i = 0; i < routeData['stops'].length; i++) {
        await _firestore.collection('route_stops').add({
          'routeId': 'route_line_$lineNumber',
          'stationId': routeData['stops'][i],
          'stopOrder': i,
          'stopName': routeData['stopNames'][i],
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
    }

    debugPrint('[FirestoreInit] Firestore seeding complete!');
  }

  Map<String, Map<String, dynamic>> _getHubStations() {
    return {
      'transtu_hub_tunis_marine': {
        'name': 'محطة تونس البحرية',
        'nameFr': 'Tunis Marine',
        'cityId': 'tunis',
        'latitude': 36.8065,
        'longitude': 10.1630,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Tunis Marine',
        'isMainHub': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_hub_barcelone': {
        'name': 'برشلونة',
        'nameFr': 'Barcelone',
        'cityId': 'tunis',
        'latitude': 36.8045,
        'longitude': 10.1910,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Barcelone, Tunis',
        'isMainHub': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_hub_bab_alioua': {
        'name': 'باب البحرية',
        'nameFr': 'Bab Alioua',
        'cityId': 'tunis',
        'latitude': 36.7955,
        'longitude': 10.1865,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Bab Alioua, Tunis',
        'isMainHub': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_hub_10_decembre': {
        'name': '10 ديسمبر',
        'nameFr': '10 Décembre',
        'cityId': 'tunis',
        'latitude': 36.8230,
        'longitude': 10.1560,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': '10 Décembre, Tunis',
        'isMainHub': true,
        'createdAt': FieldValue.serverTimestamp(),
      },
    };
  }

  Map<String, Map<String, dynamic>> _getDestinationStations() {
    return {
      'transtu_dest_qasr_al_andalus': {
        'name': 'قلعة الأندلس',
        'nameFr': 'Qasr Al-Andalus',
        'cityId': 'tunis',
        'latitude': 36.8420,
        'longitude': 10.1890,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Qasr Al-Andalus, Tunis',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_sidi_sofiane': {
        'name': 'سيدي سفيان',
        'nameFr': 'Sidi Sofiane',
        'cityId': 'tunis',
        'latitude': 36.8680,
        'longitude': 10.1230,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Sidi Sofiane, Tunis',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_cité_mellaha': {
        'name': 'حي الملاحة',
        'nameFr': 'Cité Mellaha',
        'cityId': 'tunis',
        'latitude': 36.8710,
        'longitude': 10.0950,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Cité Mellaha, Tunis',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_ghazala': {
        'name': 'غزالة',
        'nameFr': 'Ghazala',
        'cityId': 'ariana',
        'latitude': 36.9020,
        'longitude': 10.1450,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Ghazala, Ariana',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_raoued': {
        'name': 'رواد',
        'nameFr': 'Raoued',
        'cityId': 'ariana',
        'latitude': 36.8890,
        'longitude': 10.0790,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Raoued, Ariana',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_la_goulette': {
        'name': 'حلق الوادي',
        'nameFr': 'La Goulette',
        'cityId': 'tunis',
        'latitude': 36.8210,
        'longitude': 10.3210,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'La Goulette, Tunis',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_cite_bakri': {
        'name': 'حي البكري',
        'nameFr': 'Cité Bakri',
        'cityId': 'tunis',
        'latitude': 36.8480,
        'longitude': 10.1340,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Cité Bakri, Tunis',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_el_brarjia': {
        'name': 'البرارجة',
        'nameFr': 'El Brarjia',
        'cityId': 'tunis',
        'latitude': 36.8550,
        'longitude': 10.0890,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'El Brarjia, Tunis',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_sidi_omar': {
        'name': 'سيدي عمر',
        'nameFr': 'Sidi Omar',
        'cityId': 'tunis',
        'latitude': 36.8320,
        'longitude': 10.0680,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Sidi Omar, Tunis',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_medina_jdida': {
        'name': 'المدينة الجديدة',
        'nameFr': 'Medina Jdida',
        'cityId': 'tunis',
        'latitude': 36.8015,
        'longitude': 10.1560,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Medina Jdida, Tunis',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_mornag': {
        'name': 'مرناق',
        'nameFr': 'Mornag',
        'cityId': 'mornag',
        'latitude': 36.7510,
        'longitude': 10.3420,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Mornag',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
      'transtu_dest_ben_arous': {
        'name': 'بن عروس',
        'nameFr': 'Ben Arous',
        'cityId': 'ben_arous',
        'latitude': 36.7650,
        'longitude': 10.2340,
        'operatorsHere': ['transtu'],
        'transportTypes': ['bus'],
        'address': 'Ben Arous',
        'isMainHub': false,
        'createdAt': FieldValue.serverTimestamp(),
      },
    };
  }

  Map<String, Map<String, dynamic>> _getTranstuRoutes() {
    return {
      '44': {
        'service': {
          'lineNumber': '44',
          'directionAr': 'قلعة الأندلس',
          'destinationNameFr': 'Qasr Al-Andalus',
          'hubStationId': 'transtu_hub_tunis_marine',
          'firstDepartureFromHub': '04:30',
          'lastDepartureFromHub': '23:30',
          'operatingDays': [0, 1, 2, 3, 4, 5, 6],
          'createdAt': FieldValue.serverTimestamp(),
        },
        'stops': ['transtu_hub_tunis_marine', 'transtu_dest_qasr_al_andalus'],
        'stopNames': ['Tunis Marine', 'Qasr Al-Andalus'],
      },
      '6': {
        'service': {
          'lineNumber': '6',
          'directionAr': 'سيدي سفيان',
          'destinationNameFr': 'Sidi Sofiane',
          'hubStationId': 'transtu_hub_10_decembre',
          'firstDepartureFromHub': '05:00',
          'lastDepartureFromHub': '20:00',
          'operatingDays': [0, 1, 2, 3, 4, 5, 6],
          'createdAt': FieldValue.serverTimestamp(),
        },
        'stops': ['transtu_hub_10_decembre', 'transtu_dest_sidi_sofiane'],
        'stopNames': ['10 Décembre', 'Sidi Sofiane'],
      },
      '20': {
        'service': {
          'lineNumber': '20',
          'directionAr': 'قرطاج',
          'destinationNameFr': 'Carthage',
          'hubStationId': 'transtu_hub_10_decembre',
          'firstDepartureFromHub': '04:20',
          'lastDepartureFromHub': '23:10',
          'operatingDays': [0, 1, 2, 3, 4, 5, 6],
          'createdAt': FieldValue.serverTimestamp(),
        },
        'stops': ['transtu_hub_10_decembre', 'transtu_dest_ghazala', 'transtu_dest_la_goulette'],
        'stopNames': ['10 Décembre', 'Ghazala', 'La Goulette'],
      },
      '27': {
        'service': {
          'lineNumber': '27',
          'directionAr': 'سيدي عمر',
          'destinationNameFr': 'Sidi Omar',
          'hubStationId': 'transtu_hub_10_decembre',
          'firstDepartureFromHub': '05:50',
          'lastDepartureFromHub': '20:05',
          'operatingDays': [0, 1, 2, 3, 4, 5, 6],
          'createdAt': FieldValue.serverTimestamp(),
        },
        'stops': ['transtu_hub_10_decembre', 'transtu_dest_el_brarjia', 'transtu_dest_sidi_omar'],
        'stopNames': ['10 Décembre', 'El Brarjia', 'Sidi Omar'],
      },
      '32': {
        'service': {
          'lineNumber': '32',
          'directionAr': 'درج شاكر',
          'destinationNameFr': 'Dragh Shaker',
          'hubStationId': 'transtu_hub_10_decembre',
          'firstDepartureFromHub': '03:10',
          'lastDepartureFromHub': '23:15',
          'operatingDays': [0, 1, 2, 3, 4, 5, 6],
          'createdAt': FieldValue.serverTimestamp(),
        },
        'stops': ['transtu_hub_10_decembre', 'transtu_dest_cite_bakri'],
        'stopNames': ['10 Décembre', 'Cité Bakri'],
      },
      '5': {
        'service': {
          'lineNumber': '5',
          'directionAr': 'الشرقة',
          'destinationNameFr': 'Charguia',
          'hubStationId': 'transtu_hub_tunis_marine',
          'firstDepartureFromHub': '04:15',
          'lastDepartureFromHub': '23:15',
          'operatingDays': [0, 1, 2, 3, 4, 5, 6],
          'createdAt': FieldValue.serverTimestamp(),
        },
        'stops': ['transtu_hub_tunis_marine', 'transtu_dest_medina_jdida'],
        'stopNames': ['Tunis Marine', 'Medina Jdida'],
      },
      '50': {
        'service': {
          'lineNumber': '50',
          'directionAr': 'الشرقة',
          'destinationNameFr': 'Charguia',
          'hubStationId': 'transtu_hub_bab_alioua',
          'firstDepartureFromHub': '06:50',
          'lastDepartureFromHub': '20:00',
          'operatingDays': [0, 1, 2, 3, 4, 5, 6],
          'createdAt': FieldValue.serverTimestamp(),
        },
        'stops': ['transtu_hub_bab_alioua', 'transtu_dest_medina_jdida'],
        'stopNames': ['Bab Alioua', 'Medina Jdida'],
      },
    };
  }

  /// Force re-initialization (clear and reseed)
  Future<void> reinitialize() async {
    _isInitialized = false;
    await initialize();
  }
}
