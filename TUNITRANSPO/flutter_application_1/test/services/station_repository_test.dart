import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:tuni_transport/services/station_repository.dart';

Future<void> _seedStation(
  FakeFirebaseFirestore firestore, {
  required String id,
  required String name,
  required String cityId,
  required List<String> operatorsHere,
  double latitude = 36.8,
  double longitude = 10.18,
  bool isMainHub = false,
}) async {
  await firestore.collection('stations').doc(id).set({
    'name': name,
    'cityId': cityId,
    'latitude': latitude,
    'longitude': longitude,
    'address': null,
    'transportTypes': ['train'],
    'operatorsHere': operatorsHere,
    'services': {
      'wifi': false,
      'toilet': true,
      'cafe': false,
      'parking': false,
    },
    'isMainHub': isMainHub,
    'createdAt': Timestamp.now(),
  });
}

void main() {
  group('StationRepository alias search', () {
    late FakeFirebaseFirestore firestore;
    late StationRepository repository;

    setUp(() async {
      firestore = FakeFirebaseFirestore();

      await _seedStation(
        firestore,
        id: 'bs_tunis_ville',
        name: 'Tunis Ville',
        cityId: 'tunis',
        operatorsHere: const [
          'sncft',
          'sncft_banlieue_sud',
          'sncft_banlieue_d',
          'sncft_banlieue_e',
        ],
        latitude: 36.7992,
        longitude: 10.1802,
        isMainHub: true,
      );
      await _seedStation(
        firestore,
        id: 'rd_saida_manoubia',
        name: 'Saida Manoubia',
        cityId: 'tunis',
        operatorsHere: const ['sncft', 'sncft_banlieue_d', 'sncft_banlieue_e'],
        latitude: 36.8050,
        longitude: 10.1900,
      );
      await _seedStation(
        firestore,
        id: 'bs_ezzahra',
        name: 'Ezzahra',
        cityId: 'ezzahra',
        operatorsHere: const ['sncft_banlieue_sud'],
        latitude: 36.7400,
        longitude: 10.2690,
      );
      await _seedStation(
        firestore,
        id: 'bs_hammam_echatt',
        name: 'Hammam Echatt',
        cityId: 'hammam_lif',
        operatorsHere: const ['sncft_banlieue_sud'],
        latitude: 36.7040,
        longitude: 10.3370,
      );
      await _seedStation(
        firestore,
        id: 'ms_aeroport',
        name: 'Aéroport Skanès-Monastir',
        cityId: 'monastir',
        operatorsHere: const ['sncft_sahel'],
        latitude: 35.7572,
        longitude: 10.7548,
      );
      await _seedStation(
        firestore,
        id: 'bs_erriadh',
        name: 'Erriadh',
        cityId: 'borj_cedria',
        operatorsHere: const ['sncft_banlieue_sud'],
        latitude: 36.6710,
        longitude: 10.3800,
      );
      await _seedStation(
        firestore,
        id: 'bs_megrine_riadh',
        name: 'Megrine Riadh',
        cityId: 'tunis',
        operatorsHere: const ['sncft_banlieue_sud'],
        latitude: 36.7700,
        longitude: 10.2040,
      );
      await _seedStation(
        firestore,
        id: 'rd_gobaa',
        name: 'Gobaa',
        cityId: 'manouba',
        operatorsHere: const ['sncft', 'sncft_banlieue_d'],
        latitude: 36.8200,
        longitude: 10.0500,
      );
      await _seedStation(
        firestore,
        id: 'rd_gobaa_ville',
        name: 'Gobaa Ville',
        cityId: 'manouba',
        operatorsHere: const ['sncft', 'sncft_banlieue_d'],
        latitude: 36.8250,
        longitude: 10.0400,
      );
      await _seedStation(
        firestore,
        id: 'bus_tunis_centre',
        name: 'Tunis Centre Bus',
        cityId: 'tunis',
        operatorsHere: const ['transtu_bus'],
        latitude: 36.7990,
        longitude: 10.1800,
      );

      repository = StationRepository(firestore);
    });

    test('maps common aliases to canonical stations', () async {
      final tunis = await repository.searchStationsByName('Tunis');
      final manoubia = await repository.searchStationsByName('Saida Manoubia');
      final zahra = await repository.searchStationsByName('Ez-Zahra');
      final chott = await repository.searchStationsByName('Hammam Chott');
      final airport = await repository.searchStationsByName('Aeroport');

      expect(tunis, isNotEmpty);
      expect(tunis.first.id, 'bs_tunis_ville');

      expect(manoubia, isNotEmpty);
      expect(manoubia.first.id, 'rd_saida_manoubia');

      expect(zahra, isNotEmpty);
      expect(zahra.first.id, 'bs_ezzahra');

      expect(chott, isNotEmpty);
      expect(chott.first.id, 'bs_hammam_echatt');

      expect(airport, isNotEmpty);
      expect(airport.first.id, 'ms_aeroport');
    });

    test('prefers Erriadh for generic Riadh query', () async {
      final riadh = await repository.searchStationsByName('Riadh');

      expect(riadh, isNotEmpty);
      expect(riadh.first.id, 'bs_erriadh');
      expect(riadh.map((station) => station.id), contains('bs_megrine_riadh'));
    });

    test('keeps distinct stations distinguishable', () async {
      final gobaaVille = await repository.searchStationsByName('Gobaa Ville');
      final gobaa = await repository.searchStationsByName('Gobaa');

      expect(gobaaVille, isNotEmpty);
      expect(gobaaVille.first.id, 'rd_gobaa_ville');

      expect(gobaa, isNotEmpty);
      expect(gobaa.map((station) => station.id), contains('rd_gobaa'));
    });

    test('returns nearest supported rail stations in distance order', () async {
      final nearest = await repository.findNearestStations(
        latitude: 36.7991,
        longitude: 10.1801,
        limit: 3,
      );

      expect(nearest, hasLength(3));
      expect(nearest.first.station.id, 'bs_tunis_ville');
      expect(
        nearest.map((candidate) => candidate.station.id),
        isNot(contains('bus_tunis_centre')),
      );
      expect(
        nearest[0].distanceKm <= nearest[1].distanceKm &&
            nearest[1].distanceKm <= nearest[2].distanceKm,
        isTrue,
      );
    });
  });
}