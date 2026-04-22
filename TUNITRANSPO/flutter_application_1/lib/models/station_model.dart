import 'dart:math' as math;

import 'package:cloud_firestore/cloud_firestore.dart';

class Station {
  final String id;
  final String name;       // French (canonical, always populated)
  final String? nameAr;    // Arabic
  final String? nameEn;    // English
  final String cityId;
  final double latitude;
  final double longitude;
  final String? address;
  final List<String> transportTypes; // bus, train, metro
  final List<String> operatorsHere; // SNCFT, SNTRI, SMTC, etc.
  final StationServices? services;
  final bool isMainHub;
  final DateTime createdAt;

  const Station({
    required this.id,
    required this.name,
    this.nameAr,
    this.nameEn,
    required this.cityId,
    required this.latitude,
    required this.longitude,
    this.address,
    required this.transportTypes,
    required this.operatorsHere,
    this.services,
    this.isMainHub = false,
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory Station.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Station(
      id: doc.id,
      name: data['name'] ?? '',
      nameAr: data['nameAr']?.toString(),
      nameEn: data['nameEn']?.toString(),
      cityId: data['cityId'] ?? '',
      latitude: (data['latitude'] ?? 0.0).toDouble(),
      longitude: (data['longitude'] ?? 0.0).toDouble(),
      address: data['address'],
      transportTypes: List<String>.from(data['transportTypes'] ?? []),
      operatorsHere: List<String>.from(data['operatorsHere'] ?? []),
      services: data['services'] != null
          ? StationServices.fromMap(Map<String, dynamic>.from(data['services']))
          : null,
      isMainHub: data['isMainHub'] ?? false,
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() => {
        'name': name,
        'nameAr': nameAr,
        'nameEn': nameEn,
        'cityId': cityId,
        'latitude': latitude,
        'longitude': longitude,
        'address': address,
        'transportTypes': transportTypes,
        'operatorsHere': operatorsHere,
        'services': services?.toMap(),
        'isMainHub': isMainHub,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Returns the display name for the given locale language code.
  /// Falls back to [name] (French) if the translation is missing.
  String localizedName(String languageCode) {
    switch (languageCode) {
      case 'ar':
        return (nameAr?.isNotEmpty == true) ? nameAr! : name;
      case 'en':
        return (nameEn?.isNotEmpty == true) ? nameEn! : name;
      default:
        return name; // 'fr'
    }
  }

  /// Haversine distance to another station (in km)
  double distanceToStation(Station other) {
    const radiusKm = 6371.0;
    final lat1Rad = latitude * (math.pi / 180);
    final lat2Rad = other.latitude * (math.pi / 180);
    final deltaLat = (other.latitude - latitude) * (math.pi / 180);
    final deltaLng = (other.longitude - longitude) * (math.pi / 180);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radiusKm * c;
  }

  /// Haversine distance from this station to a coordinate pair (in km).
  double distanceToCoordinates(double lat, double lng) {
    const radiusKm = 6371.0;
    final lat1Rad = latitude * (math.pi / 180);
    final lat2Rad = lat * (math.pi / 180);
    final deltaLat = (lat - latitude) * (math.pi / 180);
    final deltaLng = (lng - longitude) * (math.pi / 180);

    final a = math.sin(deltaLat / 2) * math.sin(deltaLat / 2) +
        math.cos(lat1Rad) *
            math.cos(lat2Rad) *
            math.sin(deltaLng / 2) *
            math.sin(deltaLng / 2);

    final c = 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
    return radiusKm * c;
  }

  /// Copy with some fields modified
  Station copyWith({
    String? id,
    String? name,
    String? nameAr,
    String? nameEn,
    String? cityId,
    double? latitude,
    double? longitude,
    String? address,
    List<String>? transportTypes,
    List<String>? operatorsHere,
    StationServices? services,
    bool? isMainHub,
    DateTime? createdAt,
  }) {
    return Station(
      id: id ?? this.id,
      name: name ?? this.name,
      nameAr: nameAr ?? this.nameAr,
      nameEn: nameEn ?? this.nameEn,
      cityId: cityId ?? this.cityId,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      address: address ?? this.address,
      transportTypes: transportTypes ?? this.transportTypes,
      operatorsHere: operatorsHere ?? this.operatorsHere,
      services: services ?? this.services,
      isMainHub: isMainHub ?? this.isMainHub,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() => 'Station($name, $cityId)';
}

class StationServices {
  final bool hasWifi;
  final bool hasToilet;
  final bool hasCafe;
  final bool hasParking;

  const StationServices({
    this.hasWifi = false,
    this.hasToilet = false,
    this.hasCafe = false,
    this.hasParking = false,
  });

  factory StationServices.fromMap(Map<String, dynamic> map) {
    return StationServices(
      hasWifi: map['wifi'] ?? false,
      hasToilet: map['toilet'] ?? false,
      hasCafe: map['cafe'] ?? false,
      hasParking: map['parking'] ?? false,
    );
  }

  Map<String, dynamic> toMap() => {
        'wifi': hasWifi,
        'toilet': hasToilet,
        'cafe': hasCafe,
        'parking': hasParking,
      };
}
