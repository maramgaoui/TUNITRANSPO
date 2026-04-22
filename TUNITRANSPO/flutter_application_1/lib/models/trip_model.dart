import 'package:cloud_firestore/cloud_firestore.dart';

class Trip {
  final String id;
  final String routeId;
  final int tripNumber; // e.g., 501, 503, 504
  final DateTime departureTime;
  final DateTime? arrivalTime;
  final int capacity;
  final int availableSeats;
  final List<int> daysOfWeek; // 0=Sunday to 6=Saturday
  final DateTime validFrom;
  final DateTime? validTo;
  final bool isActive;
  final String? vehicleId;
  final String? driverName;
  final DateTime createdAt;

  const Trip({
    required this.id,
    required this.routeId,
    required this.tripNumber,
    required this.departureTime,
    this.arrivalTime,
    this.capacity = 300,
    this.availableSeats = 300,
    required this.daysOfWeek,
    required this.validFrom,
    this.validTo,
    this.isActive = true,
    this.vehicleId,
    this.driverName,
    required this.createdAt,
  });

  /// Convert from Firestore document
  factory Trip.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    final depTs = data['departureTime'];
    final arrTs = data['arrivalTime'];
    final validFromTs = data['validFrom'];
    final validToTs = data['validTo'];
    final createdTs = data['createdAt'];
    return Trip(
      id: doc.id,
      routeId: data['routeId'] ?? '',
      tripNumber: data['tripNumber'] ?? 0,
      departureTime: depTs is Timestamp ? depTs.toDate() : DateTime.now(),
      arrivalTime: arrTs is Timestamp ? arrTs.toDate() : null,
      capacity: data['capacity'] ?? 300,
      availableSeats: data['availableSeats'] ?? 300,
      daysOfWeek: List<int>.from(data['daysOfWeek'] ?? [0, 1, 2, 3, 4, 5, 6]),
      validFrom: validFromTs is Timestamp ? validFromTs.toDate() : DateTime.now(),
      validTo: validToTs is Timestamp ? validToTs.toDate() : null,
      isActive: data['isActive'] ?? true,
      vehicleId: data['vehicleId'],
      driverName: data['driverName'],
      createdAt: createdTs is Timestamp ? createdTs.toDate() : DateTime.now(),
    );
  }

  /// Convert to Firestore document
  Map<String, dynamic> toMap() => {
        'routeId': routeId,
        'tripNumber': tripNumber,
        'departureTime': Timestamp.fromDate(departureTime),
        'arrivalTime': arrivalTime != null ? Timestamp.fromDate(arrivalTime!) : null,
        'capacity': capacity,
        'availableSeats': availableSeats,
        'daysOfWeek': daysOfWeek,
        'validFrom': Timestamp.fromDate(validFrom),
        'validTo': validTo != null ? Timestamp.fromDate(validTo!) : null,
        'isActive': isActive,
        'vehicleId': vehicleId,
        'driverName': driverName,
        'createdAt': Timestamp.fromDate(createdAt),
      };

  /// Estimated duration of the trip
  Duration? get estimatedDuration {
    if (arrivalTime == null) return null;
    return arrivalTime!.difference(departureTime);
  }

  /// Format departure time for display (HH:MM)
  String get formattedDepartureTime {
    return '${departureTime.hour.toString().padLeft(2, '0')}:${departureTime.minute.toString().padLeft(2, '0')}';
  }

  /// Format arrival time for display (HH:MM)
  String get formattedArrivalTime {
    if (arrivalTime == null) return '--:--';
    return '${arrivalTime!.hour.toString().padLeft(2, '0')}:${arrivalTime!.minute.toString().padLeft(2, '0')}';
  }

  /// Check if trip is available on a given date
  bool isAvailableOn(DateTime date) {
    final dayOfWeek = date.weekday % 7;
    return isActive &&
        date.isAfter(validFrom.subtract(const Duration(days: 1))) &&
        (validTo == null || date.isBefore(validTo!.add(const Duration(days: 1)))) &&
        daysOfWeek.contains(dayOfWeek);
  }

  /// Occupancy percentage
  double get occupancyPercentage {
    if (capacity == 0) return 0;
    return ((capacity - availableSeats) / capacity * 100);
  }

  /// Copy with some fields modified
  Trip copyWith({
    String? id,
    String? routeId,
    int? tripNumber,
    DateTime? departureTime,
    DateTime? arrivalTime,
    int? capacity,
    int? availableSeats,
    List<int>? daysOfWeek,
    DateTime? validFrom,
    DateTime? validTo,
    bool? isActive,
    String? vehicleId,
    String? driverName,
    DateTime? createdAt,
  }) {
    return Trip(
      id: id ?? this.id,
      routeId: routeId ?? this.routeId,
      tripNumber: tripNumber ?? this.tripNumber,
      departureTime: departureTime ?? this.departureTime,
      arrivalTime: arrivalTime ?? this.arrivalTime,
      capacity: capacity ?? this.capacity,
      availableSeats: availableSeats ?? this.availableSeats,
      daysOfWeek: daysOfWeek ?? this.daysOfWeek,
      validFrom: validFrom ?? this.validFrom,
      validTo: validTo ?? this.validTo,
      isActive: isActive ?? this.isActive,
      vehicleId: vehicleId ?? this.vehicleId,
      driverName: driverName ?? this.driverName,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() =>
      'Trip(#$tripNumber, ${departureTime.hour}:${departureTime.minute} → ${arrivalTime?.hour}:${arrivalTime?.minute}, routeId: $routeId)';
}
