import 'package:cloud_firestore/cloud_firestore.dart';

class Route {
  final String id;
  final String operatorId;
  final String typeId; // bus, train, metro, louage
  final String lineNumber;
  final String name;
  final String? description;
  final String? originStationId;
  final String? destinationStationId;
  final bool isCircular;
  final bool isActive;
  final List<String> stopIds; // List of station IDs in order
  final DateTime createdAt;

  const Route({
    required this.id,
    required this.operatorId,
    required this.typeId,
    required this.lineNumber,
    required this.name,
    this.description,
    this.originStationId,
    this.destinationStationId,
    this.isCircular = false,
    this.isActive = true,
    required this.stopIds,
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory Route.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Route(
      id: doc.id,
      operatorId: data['operatorId'] ?? '',
      typeId: data['typeId'] ?? '',
      lineNumber: data['lineNumber'] ?? '',
      name: data['name'] ?? '',
      description: data['description'],
      originStationId: data['originStationId'],
      destinationStationId: data['destinationStationId'],
      isCircular: data['isCircular'] ?? false,
      isActive: data['isActive'] ?? true,
      stopIds: List<String>.from(data['stopIds'] ?? []),
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() => {
        'operatorId': operatorId,
        'typeId': typeId,
        'lineNumber': lineNumber,
        'name': name,
        'description': description,
        'originStationId': originStationId,
        'destinationStationId': destinationStationId,
        'isCircular': isCircular,
        'isActive': isActive,
        'stopIds': stopIds,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Check if route connects two stations
  bool connectsStations(String fromStationId, String toStationId) {
    final fromIndex = stopIds.indexOf(fromStationId);
    final toIndex = stopIds.indexOf(toStationId);
    return fromIndex >= 0 && toIndex > fromIndex;
  }

  /// Get stops between two stations (inclusive)
  List<String> getStopsBetween(String fromStationId, String toStationId) {
    final fromIndex = stopIds.indexOf(fromStationId);
    final toIndex = stopIds.indexOf(toStationId);
    if (fromIndex < 0 || toIndex <= fromIndex) return [];
    return stopIds.sublist(fromIndex, toIndex + 1);
  }

  /// Get number of stops between two stations
  int getNumberOfStops(String fromStationId, String toStationId) {
    final stops = getStopsBetween(fromStationId, toStationId);
    return stops.isEmpty ? 0 : stops.length - 1;
  }

  /// Copy with some fields modified
  Route copyWith({
    String? id,
    String? operatorId,
    String? typeId,
    String? lineNumber,
    String? name,
    String? description,
    String? originStationId,
    String? destinationStationId,
    bool? isCircular,
    bool? isActive,
    List<String>? stopIds,
    DateTime? createdAt,
  }) {
    return Route(
      id: id ?? this.id,
      operatorId: operatorId ?? this.operatorId,
      typeId: typeId ?? this.typeId,
      lineNumber: lineNumber ?? this.lineNumber,
      name: name ?? this.name,
      description: description ?? this.description,
      originStationId: originStationId ?? this.originStationId,
      destinationStationId: destinationStationId ?? this.destinationStationId,
      isCircular: isCircular ?? this.isCircular,
      isActive: isActive ?? this.isActive,
      stopIds: stopIds ?? this.stopIds,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Route(${lineNumber}: $name, ${stopIds.length} stops, operatorId: $operatorId)';
}

class RouteStop {
  final String id;
  final String routeId;
  final String stationId;
  final int stopOrder;
  final int estimatedArrivalTimeMinutes; // Minutes from route start
  final String? arrivalNote;
  final DateTime createdAt;

  const RouteStop({
    required this.id,
    required this.routeId,
    required this.stationId,
    required this.stopOrder,
    required this.estimatedArrivalTimeMinutes,
    this.arrivalNote,
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory RouteStop.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return RouteStop(
      id: doc.id,
      routeId: data['routeId'] ?? '',
      stationId: data['stationId'] ?? '',
      stopOrder: data['stopOrder'] ?? 0,
      estimatedArrivalTimeMinutes: data['estimatedArrivalTimeMinutes'] ?? 0,
      arrivalNote: data['arrivalNote'],
      createdAt: (data['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() => {
        'routeId': routeId,
        'stationId': stationId,
        'stopOrder': stopOrder,
        'estimatedArrivalTimeMinutes': estimatedArrivalTimeMinutes,
        'arrivalNote': arrivalNote,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  @override
  String toString() =>
      'RouteStop(#$stopOrder: stationId=$stationId, eta=${estimatedArrivalTimeMinutes}min)';
}
