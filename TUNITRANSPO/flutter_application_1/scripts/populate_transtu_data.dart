// Script to populate all TRANSTU stations and routes from timetables into Firestore.
// Run this to ensure all stations in the timetables are available in the app.
// This module provides data structures and helper functions for seeding
// the Firestore database with TRANSTU bus line information.

import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

const transtu2025_2026Data = {
  // Hub stations (المحطات الرئيسية)
  'transtu_hub_tunis_marine': {
    'name': 'محطة تونس البحرية',
    'nameFr': 'Tunis Marine',
    'cityId': 'tunis',
    'latitude': 36.8065,
    'longitude': 10.1630,
    'type': 'hub',
    'operators': ['transtu'],
  },
  'transtu_hub_barcelone': {
    'name': 'برشلونة',
    'nameFr': 'Barcelone',
    'cityId': 'tunis',
    'latitude': 36.8045,
    'longitude': 10.1910,
    'type': 'hub',
    'operators': ['transtu'],
  },
  'transtu_hub_jardin_thameur': {
    'name': 'جنينة ثامر',
    'nameFr': 'Jardin Thameur',
    'cityId': 'tunis',
    'latitude': 36.8145,
    'longitude': 10.1745,
    'type': 'hub',
    'operators': ['transtu'],
  },
  'transtu_hub_bab_alioua': {
    'name': 'باب البحرية',
    'nameFr': 'Bab Alioua',
    'cityId': 'tunis',
    'latitude': 36.7955,
    'longitude': 10.1865,
    'type': 'hub',
    'operators': ['transtu'],
  },
  'transtu_hub_slimlen_kahia': {
    'name': 'سليمان كاهية',
    'nameFr': 'Slimane Kahia',
    'cityId': 'tunis',
    'latitude': 36.8230,
    'longitude': 10.1560,
    'type': 'hub',
    'operators': ['transtu'],
  },
  
  // Destination stations from timetables (محطات الوجهة)
  'transtu_dest_qasr_al_andalus': {
    'name': 'قلعة الأندلس',
    'nameFr': 'Qasr Al-Andalus',
    'cityId': 'tunis',
    'latitude': 36.8420,
    'longitude': 10.1890,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_sidi_sofiane': {
    'name': 'سيدي سفيان',
    'nameFr': 'Sidi Sofiane',
    'cityId': 'tunis',
    'latitude': 36.8680,
    'longitude': 10.1230,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_cité_mellaha': {
    'name': 'حي الملاحة',
    'nameFr': 'Cité Mellaha',
    'cityId': 'tunis',
    'latitude': 36.8710,
    'longitude': 10.0950,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_ghazala': {
    'name': 'غزالة',
    'nameFr': 'Ghazala',
    'cityId': 'ariana',
    'latitude': 36.9020,
    'longitude': 10.1450,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_raoued': {
    'name': 'رواد',
    'nameFr': 'Raoued',
    'cityId': 'ariana',
    'latitude': 36.8890,
    'longitude': 10.0790,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_la_goulette': {
    'name': 'حلق الوادي',
    'nameFr': 'La Goulette',
    'cityId': 'tunis',
    'latitude': 36.8210,
    'longitude': 10.3210,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_cite_bakri': {
    'name': 'حي البكري',
    'nameFr': 'Cité Bakri',
    'cityId': 'tunis',
    'latitude': 36.8480,
    'longitude': 10.1340,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_ariana_brarjia': {
    'name': 'أريانة البرارجة',
    'nameFr': 'Ariana Brarjia',
    'cityId': 'ariana',
    'latitude': 36.9150,
    'longitude': 10.0950,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_el_brarjia': {
    'name': 'البرارجة',
    'nameFr': 'El Brarjia',
    'cityId': 'tunis',
    'latitude': 36.8550,
    'longitude': 10.0890,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_sidi_omar': {
    'name': 'سيدي عمر',
    'nameFr': 'Sidi Omar',
    'cityId': 'tunis',
    'latitude': 36.8320,
    'longitude': 10.0680,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_medina_jdida': {
    'name': 'المدينة الجديدة',
    'nameFr': 'Medina Jdida',
    'cityId': 'tunis',
    'latitude': 36.8015,
    'longitude': 10.1560,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_mornag': {
    'name': 'مرناق',
    'nameFr': 'Mornag',
    'cityId': 'mornag',
    'latitude': 36.7510,
    'longitude': 10.3420,
    'type': 'stop',
    'operators': ['transtu'],
  },
  'transtu_dest_ben_arous': {
    'name': 'بن عروس',
    'nameFr': 'Ben Arous',
    'cityId': 'ben_arous',
    'latitude': 36.7650,
    'longitude': 10.2340,
    'type': 'stop',
    'operators': ['transtu'],
  },
};

/// Bus service routes from timetables
const transtu2025_2026Routes = {
  '44': {
    'lineNumber': '44',
    'direction': 'قلعة الأندلس',
    'directionFr': 'Qasr Al-Andalus',
    'stops': ['transtu_hub_tunis_marine', 'transtu_dest_qasr_al_andalus'],
    'firstDeparture': '04:30',
    'lastDeparture': '23:30',
  },
  '6': {
    'lineNumber': '6',
    'direction': 'سيدي سفيان',
    'directionFr': 'Sidi Sofiane',
    'stops': ['transtu_hub_10_decembre', 'transtu_dest_sidi_sofiane'],
    'firstDeparture': '05:00',
    'lastDeparture': '20:00',
  },
  '20': {
    'lineNumber': '20',
    'direction': 'قرطاج',
    'directionFr': 'Carthage',
    'stops': ['transtu_hub_10_decembre', 'transtu_dest_ghazala', 'transtu_dest_la_goulette'],
    'firstDeparture': '04:20',
    'lastDeparture': '23:10',
  },
  '27': {
    'lineNumber': '27',
    'direction': 'سيدي عمر',
    'directionFr': 'Sidi Omar',
    'stops': ['transtu_hub_10_decembre', 'transtu_dest_el_brarjia', 'transtu_dest_sidi_omar'],
    'firstDeparture': '05:50',
    'lastDeparture': '20:05',
  },
  '32': {
    'lineNumber': '32',
    'direction': 'درج شاكر',
    'directionFr': 'Dragh Shaker',
    'stops': ['transtu_hub_10_decembre', 'transtu_dest_cite_bakri'],
    'firstDeparture': '03:10',
    'lastDeparture': '23:15',
  },
  '5': {
    'lineNumber': '5',
    'direction': 'الشرقة',
    'directionFr': 'Charguia',
    'stops': ['transtu_hub_tunis_marine', 'transtu_dest_medina_jdida'],
    'firstDeparture': '04:15',
    'lastDeparture': '23:15',
  },
  '50': {
    'lineNumber': '50',
    'direction': 'الشرقة',
    'directionFr': 'Charguia',
    'stops': ['transtu_hub_bab_alioua', 'transtu_dest_medina_jdida'],
    'firstDeparture': '06:50',
    'lastDeparture': '20:00',
  },
};

Future<void> populateTranstuData(FirebaseFirestore firestore) async {
  debugPrint('🚀 Starting TRANSTU data population...');
  
  int stationsAdded = 0;
  int routesAdded = 0;
  
  // 1. Add all stations
  debugPrint('📍 Adding stations...');
  for (final entry in transtu2025_2026Data.entries) {
    final stationId = entry.key;
    final stationData = entry.value;
    
    try {
      await firestore.collection('stations').doc(stationId).set({
        'name': stationData['name'],
        'nameFr': stationData['nameFr'],
        'cityId': stationData['cityId'],
        'latitude': stationData['latitude'],
        'longitude': stationData['longitude'],
        'operatorsHere': stationData['operators'],
        'transportTypes': ['bus'],
        'address': stationData['nameFr'],
        'services': {
          'hasWifi': false,
          'hasToilet': false,
          'hasCafe': false,
          'hasTicketOffice': true,
        },
        'isMainHub': stationData['type'] == 'hub',
        'createdAt': FieldValue.serverTimestamp(),
      });
      stationsAdded++;
      debugPrint('  ✓ Added station: ${stationData['nameFr']}');
    } catch (e) {
      debugPrint('  ✗ Error adding station $stationId: $e');
    }
  }
  
  // 2. Add bus services/routes
  debugPrint('\n🚌 Adding bus services...');
  for (final entry in transtu2025_2026Routes.entries) {
    final lineNumber = entry.key;
    final routeData = entry.value;
    
    try {
      final docId = 'transtu_line_$lineNumber';
      final stops = (routeData['stops'] as List<dynamic>?) ?? [];
      
      if (stops.isEmpty) {
        debugPrint('  ✗ Line $lineNumber has no stops');
        continue;
      }
      
      await firestore.collection('bus_services').doc(docId).set({
        'lineNumber': lineNumber,
        'directionAr': routeData['direction'] as String?,
        'destinationNameFr': routeData['directionFr'] as String?,
        'hubStationId': stops.first as String,
        'firstDepartureFromHub': routeData['firstDeparture'] as String?,
        'lastDepartureFromHub': routeData['lastDeparture'] as String?,
        'operatingDays': [0, 1, 2, 3, 4, 5, 6], // All days
        'createdAt': FieldValue.serverTimestamp(),
      });
      routesAdded++;
      debugPrint('  ✓ Added line: $lineNumber - ${routeData['directionFr']}');
      
      // 3. Add route stops
      for (int i = 0; i < stops.length; i++) {
        final stopId = stops[i] as String;
        await firestore.collection('route_stops').add({
          'routeId': 'route_line_$lineNumber',
          'stationId': stopId,
          'stopOrder': i,
          'stopName': transtu2025_2026Data[stopId]?['nameFr'] ?? stopId,
          'createdAt': FieldValue.serverTimestamp(),
        });
      }
      debugPrint('    ✓ Added ${stops.length} stops for line $lineNumber');
    } catch (e) {
      debugPrint('  ✗ Error adding line $lineNumber: $e');
    }
  }
  
  debugPrint('\n✅ Data population complete!');
  debugPrint('📊 Summary:');
  debugPrint('   - Stations added: $stationsAdded');
  debugPrint('   - Routes added: $routesAdded');
}

// Usage in main.dart or during app initialization:
// Future<void> seedData() async {
//   await populateTranstuData(FirebaseFirestore.instance);
// }
